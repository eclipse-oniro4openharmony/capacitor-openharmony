import { CapacitorPlugin } from "../CapacitorPlugin";
import { PluginCall } from "../PluginCall";
import { fileIo as fs, picker } from "@kit.CoreFileKit";
import { common } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { buffer } from "@kit.ArkTS";

class ReadFileResult {
  data: string = "";
}

enum Encoding {
  UTF8 = "utf8",
  ASCII = "ascii",
  UTF16 = "utf16",
}

class WriteFileResult {
  uri: string = "";
}

class ReaddirResult {
  files: string[] = [];
}

class GetUriResult {
  uri: string = "";
}

class StatResult {
  type: string = "";
  size: number = 0;
  mtime: number = 0;
  ctime: number = 0;
  atime: number = 0;
}

class PermissionStatus {
  publicStorage: string = "granted";
}

export class FilesystemPlugin extends CapacitorPlugin {
  getPluginId(): string {
    return "Filesystem";
  }

  getMethods(): string[] {
    return [
      "readFile",
      "writeFile",
      "appendFile",
      "deleteFile",
      "mkdir",
      "rmdir",
      "readdir",
      "getUri",
      "stat",
      "rename",
      "copy",
      "checkPermissions",
      "requestPermissions",
    ];
  }

  private getPath(path: string, directory: string | undefined): string {
    let baseDir = this.context.filesDir;
    if (directory) {
      switch (directory) {
        case "CACHE":
          baseDir = this.context.cacheDir;
          break;
        case "DATA":
          baseDir = this.context.filesDir;
          break;
        case "DOCUMENTS":
          baseDir = this.context.filesDir; // Simplified for MVP
          break;
        case "EXTERNAL":
          baseDir = this.context.filesDir;
          break;
        case "EXTERNAL_STORAGE":
          baseDir = this.context.filesDir;
          break;
      }
    }

    if (path.startsWith("file://")) {
      return path.replace("file://", "");
    }

    if (path.startsWith("/")) {
      return path;
    }

    return baseDir + "/" + path;
  }

  private async writeData(fd: number, data: string, encoding?: string): Promise<void> {
    if (!encoding) {
      const bytes = buffer.from(data, "base64").buffer;
      await fs.write(fd, bytes);
    } else {
      const enc = encoding.toLowerCase();
      if (enc === Encoding.UTF8 || enc === "utf-8") {
        await fs.write(fd, data);
      } else if (enc === Encoding.ASCII) {
        const bytes = buffer.from(data, "ascii").buffer;
        await fs.write(fd, bytes);
      } else if (enc === Encoding.UTF16 || enc === "utf-16") {
        const bytes = buffer.from(data, "utf16le").buffer;
        await fs.write(fd, bytes);
      } else {
        throw new Error(`Unsupported encoding: ${encoding}`);
      }
    }
  }

  private async readData(fd: number, encoding?: string): Promise<string> {
    const stat = await fs.stat(fd);
    const arrayBuffer = new ArrayBuffer(stat.size);
    await fs.read(fd, arrayBuffer);

    if (!encoding) {
      return buffer.from(arrayBuffer).toString("base64");
    } else {
      const enc = encoding.toLowerCase();
      if (enc === Encoding.UTF8 || enc === "utf-8") {
        return buffer.from(arrayBuffer).toString("utf8");
      } else if (enc === Encoding.ASCII) {
        return buffer.from(arrayBuffer).toString("ascii");
      } else if (enc === Encoding.UTF16 || enc === "utf-16") {
        return buffer.from(arrayBuffer).toString("utf16le");
      } else {
        throw new Error(`Unsupported encoding: ${encoding}`);
      }
    }
  }

  async readFile(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");
    const encoding = call.getString("encoding");

    if (!path) {
      call.reject("Must provide a path");
      return;
    }

    const fullPath = this.getPath(path, directory);

    try {
      const file = await fs.open(fullPath, fs.OpenMode.READ_ONLY);
      try {
        const data = await this.readData(file.fd, encoding);
        let res: ReadFileResult = { data };
        call.resolve(res);
      } finally {
        await fs.close(file);
      }
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to read file");
    }
  }

  async writeFile(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");
    const data = call.getString("data") ?? "";
    const encoding = call.getString("encoding");
    const recursive = call.getBoolean("recursive");

    if (!path) {
      call.reject("Must provide a path");
      return;
    }

    if (directory === "DOCUMENTS") {
      try {
        const documentSaveOptions = new picker.DocumentSaveOptions();
        documentSaveOptions.newFileNames = [path];

        const documentViewPicker = new picker.DocumentViewPicker(this.context);
        const uris = await documentViewPicker.save(documentSaveOptions);

        if (uris && uris.length > 0) {
          const uri = uris[0];
          const file = await fs.open(
            uri,
            fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC,
          );

          try {
            await this.writeData(file.fd, data, encoding);
          } finally {
            await fs.close(file);
          }

          let res: WriteFileResult = { uri: uri };
          call.resolve(res);
        } else {
          call.reject("User cancelled document selection");
        }
      } catch (err) {
        const bErr = err as BusinessError;
        call.reject(bErr.message || "Failed to save document via picker");
      }
      return;
    }

    const fullPath = this.getPath(path, directory);

    try {
      if (recursive) {
        const dirPath = fullPath.substring(0, fullPath.lastIndexOf("/"));
        if (!(await fs.access(dirPath))) {
          await fs.mkdir(dirPath, true);
        }
      }

      const file = await fs.open(
        fullPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC,
      );

      try {
        await this.writeData(file.fd, data, encoding);
      } finally {
        await fs.close(file);
      }

      let res: WriteFileResult = { uri: "file://" + fullPath };
      call.resolve(res);
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to write file");
    }
  }

  async appendFile(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");
    const data = call.getString("data");
    const encoding = call.getString("encoding");

    if (!path || data === undefined) {
      call.reject("Must provide a path and data");
      return;
    }

    const fullPath = this.getPath(path, directory);

    try {
      const file = await fs.open(
        fullPath,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND,
      );

      try {
        await this.writeData(file.fd, data, encoding);
      } finally {
        await fs.close(file);
      }

      call.resolve();
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to append to file");
    }
  }

  async deleteFile(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");

    if (!path) {
      call.reject("Must provide a path");
      return;
    }

    const fullPath = this.getPath(path, directory);

    try {
      await fs.unlink(fullPath);
      call.resolve();
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to delete file");
    }
  }

  async mkdir(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");
    const recursive = call.getBoolean("recursive");

    if (!path) {
      call.reject("Must provide a path");
      return;
    }

    const fullPath = this.getPath(path, directory);

    try {
      await fs.mkdir(fullPath, recursive);
      call.resolve();
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to create directory");
    }
  }

  async rmdir(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");

    if (!path) {
      call.reject("Must provide a path");
      return;
    }

    const fullPath = this.getPath(path, directory);

    try {
      await fs.rmdir(fullPath);
      call.resolve();
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to remove directory");
    }
  }

  async readdir(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");

    if (path === undefined) {
      call.reject("Must provide a path");
      return;
    }

    const fullPath = this.getPath(path, directory);

    try {
      const files = await fs.listFile(fullPath);
      let res: ReaddirResult = { files: files };
      call.resolve(res);
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to read directory");
    }
  }

  async getUri(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");

    if (!path) {
      call.reject("Must provide a path");
      return;
    }

    const fullPath = this.getPath(path, directory);
    let res: GetUriResult = { uri: "file://" + fullPath };
    call.resolve(res);
  }

  async stat(call: PluginCall) {
    const path = call.getString("path");
    const directory = call.getString("directory");

    if (!path) {
      call.reject("Must provide a path");
      return;
    }

    const fullPath = this.getPath(path, directory);

    try {
      const stat = await fs.stat(fullPath);
      let res: StatResult = {
        type: stat.isDirectory() ? "directory" : "file",
        size: stat.size,
        mtime: stat.mtime,
        ctime: stat.ctime,
        atime: stat.atime,
      };
      call.resolve(res);
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to get stats");
    }
  }

  async rename(call: PluginCall) {
    const from = call.getString("from");
    const to = call.getString("to");
    const fromDirectory = call.getString("fromDirectory");
    const toDirectory = call.getString("toDirectory");

    if (!from || !to) {
      call.reject("Must provide from and to paths");
      return;
    }

    const fromPath = this.getPath(from, fromDirectory);
    const toPath = this.getPath(to, toDirectory);

    try {
      await fs.rename(fromPath, toPath);
      call.resolve();
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to rename");
    }
  }

  async copy(call: PluginCall) {
    const from = call.getString("from");
    const to = call.getString("to");
    const fromDirectory = call.getString("fromDirectory");
    const toDirectory = call.getString("toDirectory");

    if (!from || !to) {
      call.reject("Must provide from and to paths");
      return;
    }

    const fromPath = this.getPath(from, fromDirectory);
    const toPath = this.getPath(to, toDirectory);

    try {
      await fs.copyFile(fromPath, toPath);
      call.resolve();
    } catch (err) {
      const bErr = err as BusinessError;
      call.reject(bErr.message || "Failed to copy");
    }
  }

  async checkPermissions(call: PluginCall) {
    let res: PermissionStatus = { publicStorage: "granted" };
    call.resolve(res);
  }

  async requestPermissions(call: PluginCall) {
    let res: PermissionStatus = { publicStorage: "granted" };
    call.resolve(res);
  }
}
