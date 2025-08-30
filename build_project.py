import os
import shutil

def copy_and_replace(src_dir, dst_dir, placeholder, replacement):
    # Copy directory structure first
    if not os.path.exists(dst_dir):
        os.makedirs(dst_dir)

    for root, dirs, files in os.walk(src_dir):
        # Figure out the relative path
        rel_path = os.path.relpath(root, src_dir)
        dst_path = os.path.join(dst_dir, rel_path)

        # Make sure subdirectories exist
        os.makedirs(dst_path, exist_ok=True)

        for file in files:
            src_file = os.path.join(root, file)
            dst_file = os.path.join(dst_path, file)

            # Try reading as text, fallback to binary (for non-text files)
            try:
                with open(src_file, "r", encoding="utf-8") as f:
                    content = f.read()

                # Replace placeholder with destination path
                content = content.replace(placeholder, replacement)

                with open(dst_file, "w", encoding="utf-8") as f:
                    f.write(content)

            except UnicodeDecodeError:
                # If file isn't text, just copy it raw
                shutil.copy2(src_file, dst_file)

path = os.getcwd() + "/build/"
path = path.replace("\\", "/")

# Example usage:
os.mkdir("build")
os.mkdir("build/src")
os.mkdir("build/src/hdl")
os.mkdir("build/src/c")
os.mkdir("build/vivado")
os.mkdir("build/vitis")
copy_and_replace("src/hdl", "build/src/hdl", "$SOURCE", path)
copy_and_replace("src/c", "build/src/c", "$SOURCE", path)
copy_and_replace("src/build_vitis", "build/vitis", "$SOURCE", path)
copy_and_replace("src/build_vivado", "build/vivado", "$SOURCE", path)

