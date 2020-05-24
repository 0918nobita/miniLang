import dayjs from 'dayjs';
import fs from 'fs';
import * as vscode from 'vscode';

export function activate(context: vscode.ExtensionContext): void {
	console.log('The "psycode" extension is now active!');

	const disposable1 = vscode.commands.registerCommand('psycode.helloWorld', () => {
		vscode.window.showInformationMessage('Hello World from psycode!');
    });

    context.subscriptions.push(disposable1);
    
    const disposable2 = vscode.commands.registerCommand('psycode.generateFile', () => {
        vscode.window.showInformationMessage('Generating file...');

        const workspaces = vscode.workspace.workspaceFolders;
        if (workspaces === undefined) return;

        const currentFolder = workspaces[0].uri.fsPath;
        const newFilePath = `${currentFolder}/${dayjs().format('YYYYMMDD-HHmmss')}.txt`;
        const fileContent = 'Hello, world!\n';

        fs.appendFile(newFilePath, fileContent, (err) => {
            if (err === null) return;
            vscode.window.showErrorMessage('ファイルの生成に失敗しました');
        });
    });

    context.subscriptions.push(disposable2);
}

// eslint-disable-next-line @typescript-eslint/no-empty-function
export function deactivate(): void {}
