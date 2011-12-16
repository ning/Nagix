

## Configuration

Nagix' configuration file is a YAML file with these settings:

	mklivestatus_socket: <path to the nagios socket, this is required>
	mklivestatus_log_file: <mk livestatus log file, nagix.lql.log in the current folder by default>
	mklivestatus_log_level: <mk livestatus log level, WARN by default>

Nagix tries these paths for the configuration file (in this order):

* `.nagixrc` in the current directory
* `.nagixrc` in the home directory of the current user
* `/etc/nagixrc`

You can also pass the location of the configuration file on the command line via the `-c` argument.
