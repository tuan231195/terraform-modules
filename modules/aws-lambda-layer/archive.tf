data "external" "build" {
	program = [
		"python",
		"${path.module}/build.py"
	]
	query = {
		dist_dir = abspath("${path.module}/dist/")
		source_dir = var.source_dir
		source_type = var.source_type
		package_file = var.package_file
		rsync_pattern = join(" ", var.rsync_pattern)
	}
}