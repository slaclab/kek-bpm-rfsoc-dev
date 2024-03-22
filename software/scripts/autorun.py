#!/usr/bin/env python3

import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import subprocess

class MyHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory:
            return
        elif event.src_path.endswith('.dat'):
            time.sleep(5)
            print(f"{event.src_path} has been created. Running script...")
            subprocess.run(["python3", "makeplot.py"])  # スクリプトを実行

def main():
    path = '../datfile/'  # 監視するディレクトリのパスを指定
    event_handler = MyHandler()
    observer = Observer()
    observer.schedule(event_handler, path, recursive=False)
    observer.start()

    try:
        while True:
            time.sleep(60)
            
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

if __name__ == "__main__":
    main()
