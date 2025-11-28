import * as core from '@actions/core';
import { log } from '@winccoa-tools-pack/core-utils';

async function run() {
  try {
    const message = core.getInput('message');
    if (message) log(`Action received: ${message}`);
    core.info('Action template executed');
  } catch (err: any) {
    core.setFailed(err.message);
  }
}

run();
