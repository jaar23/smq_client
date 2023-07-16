import os
import flag
import smq
import term

fn main() {
	mut fp := flag.new_flag_parser(os.args)

	fp.application('smq client')
	fp.version('0.1')
	fp.description('smq client for interact with smq')
	fp.skip_executable()

	mut action := fp.string('action', `a`, 'none', 'Allowed action: PUT, GET, NEW, CLEAR')
	data := fp.string('data', `d`, 'none', 'Content used to put into smq')
	topic := fp.string('topic', `t`, 'none', 'Topic name of smq')

	additional_args := fp.finalize()!

	if additional_args.len > 0 {
		println('Unprocessed arguments:\n${additional_args.join_lines()}')
	}

	// println('action: ${action}')
	// println('topic: ${topic}')
	// println('data: ${data}')

	addr := '127.0.0.1'
	port := 6789

	client := smq.SmqClient.new(addr: addr, port: port)
	action = action.to_lower()
	match action {
		'put' {
			resp := client.put(topic, data)!
			dump(resp)
		}
		'get' {
			resp := client.get(topic)!
			dump(resp)
		}
		'clear' {
			resp := client.clear(topic)!
			dump(resp)
		}
		'new' {
			resp := client.new(topic)!
			dump(resp)
		}
		'count' {
			resp := client.count(topic)!
			dump(resp)
		}
		else {
			println(term.red('Unrecognized command'))
		}
	}
}
