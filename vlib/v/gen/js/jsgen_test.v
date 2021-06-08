import os

const (
	test_dir   = os.join_path('vlib', 'v', 'gen', 'js', 'tests')
	output_dir = '_js_tests/'
	v_options  = '-b js -w'
)

fn testsuite_end() {
	os.rmdir_all(output_dir) or {}
}

const there_is_node_available = is_nodejs_working()

const there_is_grep_available = is_grep_working()

fn test_example_compilation() {
	vexe := os.getenv('VEXE')
	os.chdir(os.dir(vexe))
	os.mkdir_all(output_dir) or { panic(err) }
	files := find_test_files()
	for file in files {
		path := os.join_path(test_dir, file)
		println('Testing $file')
		v_options_file := if file.ends_with('_sourcemap.v') {
			println('activate sourcemap creation')
			v_options + ' -g' // activate souremap generation
		} else {
			v_options
		}
		v_code := os.system('$vexe $v_options_file -o $output_dir${file}.js $path')
		if v_code != 0 {
			assert false
		}
		// Compilation failed
		assert v_code == 0
		if !there_is_node_available {
			println(' ... skipping running $file, there is no NodeJS present')
			continue
		}
		js_code := os.system('node $output_dir${file}.js')
		if js_code != 0 {
			assert false
		}
		// Running failed
		assert js_code == 0
		if file.ends_with('_sourcemap.v') {
			if there_is_grep_available {
				grep_code_sourcemap_found := os.system('grep -q -E "//#\\ssourceMappingURL=data:application/json;base64,[-A-Za-z0-9+/=]+$" $output_dir${file}.js')

				assert grep_code_sourcemap_found == 0
			} else {
				println(' ... skipping testing for sourcemap $file, there is no grep present')
			}
		}
	}
}

fn find_test_files() []string {
	files := os.ls(test_dir) or { panic(err) }
	// The life example never exits, so tests would hang with it, skip
	mut tests := files.filter(it.ends_with('.v')).filter(it != 'life.v')
	tests.sort()
	return tests
}

fn is_nodejs_working() bool {
	node_res := os.execute('node --version')
	if node_res.exit_code != 0 {
		return false
	}
	return true
}

fn is_grep_working() bool {
	node_res := os.execute('grep --version')
	if node_res.exit_code != 0 {
		return false
	}
	return true
}
