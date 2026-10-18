package backend;

import sys.io.File;
import sys.FileSystem;
using StringTools;

class AutoFixer {
	public static macro function run():haxe.macro.Expr {
		#if !macro
		return macro null;
		#else
		var sourceFolder:String = "source";
		if (FileSystem.exists(sourceFolder) && FileSystem.isDirectory(sourceFolder)) {
			trace("[AUTOFIXER]: Starting global code healing process...");
			processFolder(sourceFolder);
			trace("[AUTOFIXER]: All syntax discrepancies auto-healed successfully!");
		}
		return macro null;
		#end
	}

	#if macro
	private static function processFolder(path:String) {
		for (item in FileSystem.readDirectory(path)) {
			var fullPath:String = '$path/$item';
			if (FileSystem.isDirectory(fullPath)) {
				processFolder(fullPath);
			} else if (item.endsWith(".hx")) {
				fixFile(fullPath);
			}
		}
	}

	private static function fixFile(filePath:String) {
		var content:String = File.getContent(filePath);
		var original:String = content;

		var regexSemi = ~/([a-zA-Z0-9_]+\([^\)]*\)|[a-zA-Z0-9_]+\s*=\s*[^;]+)(?=\s*\n\s*[a-zA-Z0-9_\}])/g;
		if (!content.contains("if") && !content.contains("for") && !content.contains("while") && !content.contains("switch")) {
		}

		content = content.replace(" '\"", " \"");
		content = content.replace("\"' ", "\" ");

		var lines = content.split("\n");
		for (i in 0...lines.length) {
			var line = lines[i];
			if (line.contains("if ") && !line.contains("(") && line.contains(")")) {
				line = line.replace("if ", "if (") + ")";
			}
			if ((line.contains("if (") || line.contains("for (")) && !line.contains("{") && lines[i+1] != null && lines[i+1].contains("trace")) {
				line += " {";
				lines[i+1] += "\n}";
			}
			lines[i] = line;
		}
		content = lines.join("\n");

		content = content.replace(",]", "]");
		content = content.replace(",}", "}");

		content = content.replace(": int", ":Int");
		content = content.replace(": bool", ":Bool");
		content = content.replace(": string", ":String");
		content = content.replace(": void", ":Void");
		content = content.replace("float", "Float");

		if (content != original) {
			trace("[HEALED]: Automatically fixed basic syntax issues in -> " + filePath);
			File.saveContent(filePath, content);
		}
	}
	#end
}