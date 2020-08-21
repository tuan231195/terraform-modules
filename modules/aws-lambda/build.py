# Builds a zip file from the source_dir or source_file.
# Installs dependencies with pip automatically.

import os
import shlex
import shutil
import subprocess
import zipfile
import tempfile
import time
import sys
import hashlib
import json
import base64

query = json.load(sys.stdin)

source_path = query['source_path']
dist_dir = os.path.abspath(query['dist_dir'])
output_file = os.path.join(dist_dir, 'output.zip')


def clean():
    shutil.rmtree(dist_dir, ignore_errors=True)
    os.makedirs(dist_dir, exist_ok=True)


def zip_file(source_dir, destination_file):
    base = os.path.basename(destination_file)
    name, _ = os.path.splitext(base)
    temp_zip_file = os.path.join(tempfile.gettempdir(), str(time.time()) + '.zip')

    new_zip = zipfile.ZipFile(temp_zip_file, 'w')
    for root, dirs, files in os.walk(source_dir):
        for file in files:
            current_file = os.path.join(root, file)
            info = zipfile.ZipInfo.from_file(current_file, arcname=os.path.relpath(current_file, source_dir))
            info.date_time = (2000, 1, 1, 0, 0, 0)
            with open(current_file, 'rb') as fd:
                new_zip.writestr(info, fd.read(), compress_type=zipfile.ZIP_DEFLATED)
    new_zip.close()
    shutil.move(temp_zip_file, destination_file)


def copy_source():
    if os.path.isfile(source_path):
        shutil.copy(source_path, output_file)
    else:
        rsync_pattern = shlex.split(query.get('rsync_pattern', ''))
        subprocess.run(['rsync', '-az', *rsync_pattern, '.', dist_dir], cwd=source_path)
        zip_file(dist_dir, output_file)


def output():
    json.dump({
        'output_file': output_file,
        'output_hash': hash_file(output_file)
    }, sys.stdout, indent=2)
    sys.stdout.write('\n')


def hash_file(filepath):
    file_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(8192):
            file_hash.update(chunk)
    return base64.b64encode(file_hash.digest()).decode('utf-8')


if __name__ == '__main__':
    clean()
    copy_source()
    output()
