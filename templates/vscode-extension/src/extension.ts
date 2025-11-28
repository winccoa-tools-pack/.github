import * as vscode from 'vscode';
import { getExtensions } from '@winccoa-tools-pack/core-utils';

export async function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.commands.registerCommand('martin.showExtensions', async () => {
      const extensions = await getExtensions();
      vscode.window.showInformationMessage(
        `Available: ${extensions.map(e => e.name).join(', ')}`
      );
    })
  );
}

export function deactivate() {}
