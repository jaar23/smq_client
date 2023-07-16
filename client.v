module smq

import net
import io
import time

pub struct SmqClient {
mut:
	read_timeout        int = 30
	write_timeout       int = 30
	addr                string
	port                int
	blocking_connection bool
}

[params]
pub struct SmqClientConfig {
	read_timeout        int    = 30
	write_timeout       int    = 30
	addr                string = '127.0.0.1'
	port                int    = 6789
	blocking_connection bool
}

pub enum ResponseStatus {
	ok
	err
}

pub struct Response {
pub mut:
	status  ResponseStatus
	code    int
	message string
	data    ?string
}

pub enum Action {
	put
	get
	clear
	new
	count
}

pub fn parse_status(status string) ResponseStatus {
	if 'ok' == status {
		return ResponseStatus.ok
	} else {
		return ResponseStatus.err
	}
}

pub fn SmqClient.new(config SmqClientConfig) SmqClient {
	return SmqClient{
		read_timeout: config.read_timeout
		write_timeout: config.write_timeout
		addr: config.addr
		port: config.port
		blocking_connection: config.blocking_connection
	}
}

pub fn (sc SmqClient) put(topic string, data string) !Response {
	return sc.send_command(Action.put, topic, data)
}

pub fn (sc SmqClient) get(topic string) !Response {
	return sc.send_command(Action.get, topic, none)
}

pub fn (sc SmqClient) new(topic string) !Response {
	return sc.send_command(Action.new, topic, none)
}

pub fn (sc SmqClient) clear(topic string) !Response {
	return sc.send_command(Action.clear, topic, none)
}

pub fn (sc SmqClient) count(topic string) !Response {
	return sc.send_command(Action.count, topic, none)
}

fn (sc SmqClient) send_command(action Action, topic string, data ?string) !Response {
	mut conn := net.dial_tcp('${sc.addr}:${sc.port.str()}') or {
		return error('Unable to establish connection, ${err}')
	}
	conn.set_read_timeout(sc.read_timeout * time.second)
	conn.set_write_timeout(sc.write_timeout * time.second)

	match action {
		.get {
			conn.write('GET ${topic}\r\n\r\n'.bytes()) or {
				return error('Unable to send PUT request, ${err}')
			}
		}
		.put {
			if d := data {
				conn.write('PUT ${topic} ${d}\r\n\r\n'.bytes()) or {
					return error('Unable to send PUT request, ${err}')
				}
			}
		}
		.clear {
			conn.write('CLEAR ${topic}\r\n\r\n'.bytes()) or {
				return error('Unable to send GET request, ${err}')
			}
		}
		.new {
			conn.write('NEW ${topic}\r\n\r\n'.bytes()) or {
				return error('Unable to send GET request, ${err}')
			}
		}
		.count {
			conn.write('COUNT ${topic}\r\n\r\n'.bytes()) or {
				return error('Unable to send COUNT request, ${err}')
			}
		}
	}
	mut bytes_data := io.read_all(reader: conn) or {
		return error('Unable to receive response, ${err}')
	}
	conn.close() or { return error('Unable to close connection, ${err}') }
	resp := SmqClient.parse_response(bytes_data.bytestr())
	return resp
}

pub fn SmqClient.parse_response(response string) Response {
	lines := response.split('\r\n')
	mut resp := Response{
		status: ResponseStatus.ok
		code: 0
		message: ''
	}

	if lines[0].len == 0 {
		return resp
	}
	for i in 0 .. lines.len {
		if i == 0 {
			line := lines[i]
			status := line.split(' ')
			resp.status = parse_status(status[1])
		} else if i == 1 {
			line := lines[i]
			code := line.split(' ')
			resp.code = code[1].int()
		} else if i == 2 {
			line := lines[i]
			message := line.split(' ')
			resp.message = message[1..].join(' ')
		} else {
			if lines[i].len > 0 {
				resp.data = lines[i]
			}
		}
	}

	return resp
}
