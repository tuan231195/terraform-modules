data "external" "build" {
  program = ["python", "${path.module}/build.py"]

  query = {
    rsync_pattern = join(" ", var.rsync_pattern)
    source_path    = var.source_path
    dist_dir = "${path.module}/dist"
  }
}