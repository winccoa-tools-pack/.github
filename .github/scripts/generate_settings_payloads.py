"""Generate JSON payloads from .github/repository.settings.yml and .github/rulesets/*.yml.

This script is the single source of truth for converting the human-friendly YAML
configuration into the JSON payloads consumed by the GitHub REST API.

It lives in the **org repo** (winccoa-tools-pack/.github) and is downloaded
automatically by the reusable workflow ``reusable-apply-settings-and-rulesets.yml``.

Usage
-----
    # Inside a GitHub Actions step (repo root is the working directory):
    python3 generate_settings_payloads.py

    # Explicit repo root (used by the reusable workflow):
    python3 generate_settings_payloads.py --repo-root /path/to/caller/repo

Output files (all written to *repo_root*):
    repo_patch.json          – PATCH /repos/{owner}/{repo}
    topics.json              – PUT  /repos/{owner}/{repo}/topics
    security.json            – vulnerability alerts / automated fixes
    ruleset_payloads/*.json  – POST|PUT /repos/{owner}/{repo}/rulesets
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from typing import Any

import yaml

# ── Keys accepted by PATCH /repos/{owner}/{repo} ──────────────────────
PATCH_KEYS = {
    "description",
    "homepage",
    "default_branch",
    "has_issues",
    "has_wiki",
    "allow_squash_merge",
    "allow_merge_commit",
    "allow_rebase_merge",
    "allow_auto_merge",
    "delete_branch_on_merge",
}

# ── GitHub topic constraints ───────────────────────────────────────────
# Lowercase alphanumeric + hyphens, 1-50 chars, max 20 topics per repo.
TOPIC_RE = re.compile(r"^[a-z0-9][a-z0-9-]{0,49}$")
MAX_TOPICS = 20


def write_json(path: pathlib.Path, data: Any) -> None:
    path.write_text(json.dumps(data, indent=2), encoding="utf-8")


def resolve_repo_root(cli_value: str | None) -> pathlib.Path:
    """Return the repository root directory.

    Priority:
    1. Explicit ``--repo-root`` argument (used by the reusable workflow).
    2. Infer from ``__file__`` (legacy: when the script lives inside
       ``<repo>/.github/scripts/``).
    """
    if cli_value:
        return pathlib.Path(cli_value).resolve()
    return pathlib.Path(__file__).resolve().parents[2]


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate GitHub API payloads from YAML config")
    parser.add_argument(
        "--repo-root",
        default=None,
        help="Path to the caller repository root (default: infer from script location)",
    )
    args = parser.parse_args()

    repo_root = resolve_repo_root(args.repo_root)
    settings_file = repo_root / ".github" / "repository.settings.yml"
    rulesets_dir = repo_root / ".github" / "rulesets"
    out_rulesets_dir = repo_root / "ruleset_payloads"

    # ── Defaults (safe no-op) ──────────────────────────────────────────
    write_json(repo_root / "repo_patch.json", {})
    # IMPORTANT: topics are optional. JSON null means "do not touch topics".
    write_json(repo_root / "topics.json", None)
    write_json(repo_root / "security.json", {})

    # ── Parse repository.settings.yml ──────────────────────────────────
    if settings_file.exists():
        settings = yaml.safe_load(settings_file.read_text(encoding="utf-8")) or {}
        if not isinstance(settings, dict):
            raise SystemExit("repository.settings.yml must be a mapping")

        repo_patch = {
            k: settings[k]
            for k in PATCH_KEYS
            if k in settings and settings[k] is not None
        }

        if "topics" in settings:
            topics = settings.get("topics")
            if topics is None:
                topics = []
            if not isinstance(topics, list):
                raise SystemExit("topics must be a list")

            normalized = [str(t).strip().lower() for t in topics if str(t).strip()]

            # Validate, deduplicate, and enforce GitHub limits to prevent HTTP 422.
            seen: set[str] = set()
            deduped: list[str] = []
            invalid: list[str] = []
            for topic in normalized:
                if topic in seen:
                    continue
                if not TOPIC_RE.match(topic):
                    invalid.append(topic)
                    continue
                seen.add(topic)
                deduped.append(topic)

            if invalid:
                sys.stdout.write(
                    f"WARNING: Skipping invalid GitHub topics (must match {TOPIC_RE.pattern}): {', '.join(invalid)}\n"
                )

            if len(deduped) > MAX_TOPICS:
                sys.stdout.write(
                    f"WARNING: Truncating topics list to {MAX_TOPICS} (was {len(deduped)}).\n"
                )
                deduped = deduped[:MAX_TOPICS]

            write_json(repo_root / "topics.json", deduped)

        security = settings.get("security", {}) or {}
        if not isinstance(security, dict):
            raise SystemExit("security must be a mapping")

        write_json(repo_root / "repo_patch.json", repo_patch)
        write_json(repo_root / "security.json", security)

    # ── Convert rulesets YAML → JSON ───────────────────────────────────
    out_rulesets_dir.mkdir(parents=True, exist_ok=True)

    if rulesets_dir.exists():
        for yml_path in sorted(rulesets_dir.glob("*.yml")):
            data = yaml.safe_load(yml_path.read_text(encoding="utf-8")) or {}
            if not isinstance(data, dict):
                raise SystemExit(f"Ruleset {yml_path} must be a mapping")

            # Safety: never rely on hard-coded IDs from YAML
            data.pop("id", None)

            # API compatibility: for some rule types, `parameters` is not allowed.
            # Strip empty parameters blocks to avoid 422 "data matches no possible input".
            rules = data.get("rules")
            if isinstance(rules, list):
                for rule in rules:
                    if isinstance(rule, dict) and rule.get("parameters") == {}:
                        rule.pop("parameters", None)

            out = out_rulesets_dir / f"{yml_path.stem}.json"
            write_json(out, data)

    # ── Summary ────────────────────────────────────────────────────────
    sys.stdout.write(f"Prepared payloads in {repo_root}\n")
    sys.stdout.write("Files: repo_patch.json, topics.json, security.json, ruleset_payloads/*.json\n")


if __name__ == "__main__":
    main()
