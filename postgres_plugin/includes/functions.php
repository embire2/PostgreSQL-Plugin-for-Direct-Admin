<?php
/**
 * Common functions for the PostgreSQL DirectAdmin plugin
 */

/**
 * Execute a script from the scripts directory
 * 
 * @param string $script Script name
 * @param array $args Arguments for the script
 * @param array &$output Output of the script
 * @return int Exit code of the script
 */
function exec_script($script, $args = [], &$output = []) {
    // Build the command
    $scriptsDir = dirname(__FILE__) . '/../scripts/';
    $command = 'bash ' . escapeshellarg($scriptsDir . $script);
    
    // Add arguments
    foreach ($args as $arg) {
        $command .= ' ' . escapeshellarg($arg);
    }
    
    // Execute the command
    $exitCode = 0;
    exec($command, $output, $exitCode);
    
    return $exitCode;
}

/**
 * Log message to the plugin log file
 * 
 * @param string $message Message to log
 * @param string $level Log level (info, warning, error)
 * @return void
 */
function log_message($message, $level = 'info') {
    $logFile = '/var/log/directadmin/postgresql_plugin.log';
    $timestamp = date('Y-m-d H:i:s');
    $formattedMessage = "[$timestamp] [$level] $message\n";
    
    // Create log directory if it doesn't exist
    $logDir = dirname($logFile);
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    // Append to log file
    file_put_contents($logFile, $formattedMessage, FILE_APPEND);
}

/**
 * Get a list of all PostgreSQL databases
 * 
 * @return array|bool Array of database information or false on failure
 */
function get_all_databases() {
    $output = [];
    $exitCode = 0;
    
    // Execute SQL to get database list
    exec('su - postgres -c "psql -t -c \"SELECT d.datname, pg_catalog.pg_get_userbyid(d.datdba) as owner, pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) as size, pg_catalog.pg_encoding_to_char(d.encoding) as encoding, to_char(d.datcreate, \'YYYY-MM-DD HH24:MI:SS\') as created FROM pg_catalog.pg_database d WHERE d.datistemplate = false ORDER BY d.datname;\""', $output, $exitCode);
    
    if ($exitCode !== 0) {
        return false;
    }
    
    $databases = [];
    foreach ($output as $line) {
        $line = trim($line);
        if (!empty($line)) {
            $parts = preg_split('/\|/', $line);
            if (count($parts) >= 3) {
                $databases[] = [
                    'name' => trim($parts[0]),
                    'owner' => trim($parts[1]),
                    'size' => trim($parts[2]),
                    'encoding' => isset($parts[3]) ? trim($parts[3]) : 'UTF8',
                    'created' => isset($parts[4]) ? trim($parts[4]) : null
                ];
            }
        }
    }
    
    return $databases;
}

/**
 * Get a list of all PostgreSQL users
 * 
 * @return array|bool Array of user information or false on failure
 */
function get_all_pg_users() {
    $output = [];
    $exitCode = 0;
    
    // Execute SQL to get user list
    exec('su - postgres -c "psql -t -c \"SELECT r.rolname, r.rolsuper, r.rolcreaterole, r.rolcreatedb, to_char(r.rolvaliduntil, \'YYYY-MM-DD HH24:MI:SS\') as expires, r.rolcanlogin FROM pg_catalog.pg_roles r WHERE r.rolcanlogin = true ORDER BY r.rolname;\""', $output, $exitCode);
    
    if ($exitCode !== 0) {
        return false;
    }
    
    $users = [];
    foreach ($output as $line) {
        $line = trim($line);
        if (!empty($line)) {
            $parts = preg_split('/\|/', $line);
            if (count($parts) >= 3) {
                $username = trim($parts[0]);
                
                // Skip system users
                if (in_array($username, ['postgres', 'template0', 'template1'])) {
                    continue;
                }
                
                // Get database count for this user
                $dbCount = get_user_database_count($username);
                
                // Check if user is a DirectAdmin user
                $daUser = check_directadmin_user($username) ? $username : '';
                
                $users[] = [
                    'username' => $username,
                    'is_superuser' => trim($parts[1]) === 't',
                    'can_create_role' => trim($parts[2]) === 't',
                    'can_create_db' => trim($parts[3]) === 't',
                    'expires' => trim($parts[4]) !== '' ? trim($parts[4]) : null,
                    'database_count' => $dbCount,
                    'da_user' => $daUser
                ];
            }
        }
    }
    
    return $users;
}

/**
 * Get a count of databases owned by a user
 * 
 * @param string $username Username to check
 * @return int Count of databases owned by the user
 */
function get_user_database_count($username) {
    $output = [];
    $exitCode = 0;
    
    // Count databases owned by the user
    exec('su - postgres -c "psql -t -c \"SELECT COUNT(*) FROM pg_catalog.pg_database d JOIN pg_catalog.pg_roles r ON d.datdba = r.oid WHERE r.rolname = \'' . pg_escape_literal($username) . '\';\""', $output, $exitCode);
    
    if ($exitCode !== 0 || empty($output)) {
        return 0;
    }
    
    return (int)trim($output[0]);
}

/**
 * Check if a user is a DirectAdmin user
 * 
 * @param string $username Username to check
 * @return bool True if the user is a DirectAdmin user, false otherwise
 */
function check_directadmin_user($username) {
    return is_dir('/usr/local/directadmin/data/users/' . $username);
}

/**
 * Escape a literal value for PostgreSQL
 * 
 * @param string $value Value to escape
 * @return string Escaped value
 */
function pg_escape_literal($value) {
    // Simple escape for security - in a real implementation, you'd use pg_escape_literal from PHP's PostgreSQL extension
    return str_replace("'", "''", $value);
}

/**
 * Get a database count
 * 
 * @return int|bool Count of databases or false on failure
 */
function get_database_count() {
    $output = [];
    $exitCode = 0;
    
    // Count databases excluding templates
    exec('su - postgres -c "psql -t -c \"SELECT COUNT(*) FROM pg_catalog.pg_database WHERE datistemplate = false;\""', $output, $exitCode);
    
    if ($exitCode !== 0 || empty($output)) {
        return false;
    }
    
    return (int)trim($output[0]);
}

/**
 * Check if the PostgreSQL server is running
 * 
 * @return bool True if running, false otherwise
 */
function is_postgresql_running() {
    $output = [];
    $exitCode = 0;
    exec('systemctl is-active postgresql', $output, $exitCode);
    return ($exitCode === 0 && trim($output[0]) === 'active');
}

/**
 * Get PostgreSQL version
 * 
 * @return string|bool Version string or false on failure
 */
function get_postgresql_version() {
    if (!is_postgresql_running()) {
        return false;
    }
    
    $output = [];
    $exitCode = 0;
    exec('su - postgres -c "psql --version"', $output, $exitCode);
    
    if ($exitCode !== 0 || empty($output)) {
        return false;
    }
    
    return trim($output[0]);
}

/**
 * Generate a random password
 * 
 * @param int $length Length of the password
 * @return string Random password
 */
function generate_random_password($length = 12) {
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+';
    $password = '';
    
    for ($i = 0; $i < $length; $i++) {
        $password .= $chars[rand(0, strlen($chars) - 1)];
    }
    
    return $password;
}
