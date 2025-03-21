<?php
/**
 * PostgreSQL Admin API - Status
 * 
 * This file handles all status and configuration related API requests for the admin panel
 */

// Initialize session and check admin permissions
session_start();
require_once(dirname(__FILE__) . '/../../scripts/check_admin_auth.php');

// Set content type to JSON
header('Content-Type: application/json');

// Include necessary functions
require_once(dirname(__FILE__) . '/../../includes/functions.php');

// Get action from request
$action = isset($_REQUEST['action']) ? $_REQUEST['action'] : '';

// Initialize response array
$response = [
    'status' => 'error',
    'message' => 'Unknown action'
];

// Process based on action
switch ($action) {
    case 'status':
        // Get PostgreSQL status information
        $pgStatus = get_postgresql_status();
        if ($pgStatus !== false) {
            $response = [
                'status' => 'success',
                'data' => $pgStatus
            ];
        } else {
            $response['message'] = 'Failed to retrieve PostgreSQL status';
        }
        break;
        
    case 'resources':
        // Get resource usage information
        $resources = get_resource_usage();
        if ($resources !== false) {
            $response = [
                'status' => 'success',
                'data' => $resources
            ];
        } else {
            $response['message'] = 'Failed to retrieve resource usage information';
        }
        break;
        
    case 'stats':
        // Get PostgreSQL statistics
        $stats = get_postgresql_stats();
        if ($stats !== false) {
            $response = [
                'status' => 'success',
                'data' => $stats
            ];
        } else {
            $response['message'] = 'Failed to retrieve PostgreSQL statistics';
        }
        break;
        
    case 'connections':
        // Get active connections
        $connections = get_active_connections();
        if ($connections !== false) {
            $response = [
                'status' => 'success',
                'data' => $connections
            ];
        } else {
            $response['message'] = 'Failed to retrieve active connections';
        }
        break;
        
    case 'logs':
        // Get PostgreSQL logs
        $logs = get_postgresql_logs();
        if ($logs !== false) {
            $response = [
                'status' => 'success',
                'data' => $logs
            ];
        } else {
            $response['message'] = 'Failed to retrieve PostgreSQL logs';
        }
        break;
        
    case 'start':
    case 'stop':
    case 'restart':
    case 'reload':
        // Control PostgreSQL service
        $result = control_postgresql_service($action);
        if ($result === true) {
            $response = [
                'status' => 'success',
                'message' => 'PostgreSQL service ' . $action . ' command executed successfully'
            ];
        } else {
            $response['message'] = 'Failed to ' . $action . ' PostgreSQL service: ' . $result;
        }
        break;
        
    case 'get_settings':
        // Get PostgreSQL settings
        if (isset($_GET['category'])) {
            $category = $_GET['category'];
            $settings = get_postgresql_settings($category);
            
            if ($settings !== false) {
                $response = [
                    'status' => 'success',
                    'data' => $settings
                ];
            } else {
                $response['message'] = 'Failed to retrieve PostgreSQL settings for category: ' . $category;
            }
        } else {
            $response['message'] = 'Missing category parameter';
        }
        break;
        
    case 'save_settings':
        // Save PostgreSQL settings
        if (isset($_POST['category'])) {
            $category = $_POST['category'];
            
            // Remove action and category from the array to get only the settings
            $settings = $_POST;
            unset($settings['action']);
            unset($settings['category']);
            
            $result = save_postgresql_settings($category, $settings);
            if ($result === true) {
                $response = [
                    'status' => 'success',
                    'message' => 'Settings saved successfully'
                ];
            } else {
                $response['message'] = 'Failed to save settings: ' . $result;
            }
        } else {
            $response['message'] = 'Missing category parameter';
        }
        break;
        
    case 'set_parameter':
        // Set a PostgreSQL parameter
        if (isset($_POST['name']) && isset($_POST['value'])) {
            $name = trim($_POST['name']);
            $value = trim($_POST['value']);
            
            $result = set_postgresql_parameter($name, $value);
            if ($result === true) {
                $response = [
                    'status' => 'success',
                    'message' => "Parameter $name set to $value successfully"
                ];
            } else {
                $response['message'] = 'Failed to set parameter: ' . $result;
            }
        } else {
            $response['message'] = 'Missing required parameters';
        }
        break;
        
    case 'delete_parameter':
        // Delete a PostgreSQL parameter (reset to default)
        if (isset($_POST['name'])) {
            $name = trim($_POST['name']);
            
            $result = delete_postgresql_parameter($name);
            if ($result === true) {
                $response = [
                    'status' => 'success',
                    'message' => "Parameter $name reset to default successfully"
                ];
            } else {
                $response['message'] = 'Failed to reset parameter: ' . $result;
            }
        } else {
            $response['message'] = 'Missing name parameter';
        }
        break;
        
    case 'get_custom_parameters':
        // Get custom PostgreSQL parameters
        $parameters = get_custom_parameters();
        if ($parameters !== false) {
            $response = [
                'status' => 'success',
                'data' => $parameters
            ];
        } else {
            $response['message'] = 'Failed to retrieve custom parameters';
        }
        break;
        
    case 'get_config_file':
        // Get content of a PostgreSQL configuration file
        if (isset($_GET['filename'])) {
            $filename = $_GET['filename'];
            
            // Validate filename to prevent directory traversal
            if (!in_array($filename, ['postgresql.conf', 'pg_hba.conf', 'pg_ident.conf'])) {
                $response['message'] = 'Invalid filename requested';
                break;
            }
            
            $content = get_config_file_content($filename);
            if ($content !== false) {
                $response = [
                    'status' => 'success',
                    'data' => $content
                ];
            } else {
                $response['message'] = "Failed to retrieve content of $filename";
            }
        } else {
            $response['message'] = 'Missing filename parameter';
        }
        break;
        
    default:
        $response['message'] = 'Unknown action: ' . $action;
        break;
}

// Output response as JSON
echo json_encode($response);
exit;

/**
 * Get PostgreSQL status information
 * 
 * @return array|bool Array of status information or false on failure
 */
function get_postgresql_status() {
    // Check if PostgreSQL is running
    $output = [];
    $exitCode = 0;
    exec('systemctl is-active postgresql', $output, $exitCode);
    $running = ($exitCode === 0 && trim($output[0]) === 'active');
    
    // Get version information
    $version = '';
    if ($running) {
        $versionOutput = [];
        exec('su - postgres -c "psql --version"', $versionOutput, $versionExitCode);
        if ($versionExitCode === 0 && !empty($versionOutput)) {
            $version = trim($versionOutput[0]);
        }
    }
    
    // Get data directory
    $dataDir = '';
    if ($running) {
        $dirOutput = [];
        exec('su - postgres -c "psql -t -c \"SHOW data_directory;\""', $dirOutput, $dirExitCode);
        if ($dirExitCode === 0 && !empty($dirOutput)) {
            $dataDir = trim($dirOutput[0]);
        }
    }
    
    // Get log directory
    $logDir = '';
    if ($running) {
        $logOutput = [];
        exec('su - postgres -c "psql -t -c \"SHOW log_directory;\""', $logOutput, $logExitCode);
        if ($logExitCode === 0 && !empty($logOutput)) {
            $logDir = trim($logOutput[0]);
        }
    }
    
    // Get connection count
    $connections = 0;
    if ($running) {
        $connOutput = [];
        exec('su - postgres -c "psql -t -c \"SELECT COUNT(*) FROM pg_stat_activity;\""', $connOutput, $connExitCode);
        if ($connExitCode === 0 && !empty($connOutput)) {
            $connections = (int)trim($connOutput[0]);
        }
    }
    
    // Get server time
    $serverTime = '';
    if ($running) {
        $timeOutput = [];
        exec('su - postgres -c "psql -t -c \"SELECT NOW();\""', $timeOutput, $timeExitCode);
        if ($timeExitCode === 0 && !empty($timeOutput)) {
            $serverTime = trim($timeOutput[0]);
        }
    }
    
    return [
        'running' => $running,
        'version' => $version,
        'data_directory' => $dataDir,
        'log_directory' => $logDir,
        'connections' => $connections,
        'server_time' => $serverTime
    ];
}

/**
 * Get resource usage information
 * 
 * @return array|bool Array of resource usage information or false on failure
 */
function get_resource_usage() {
    // Get CPU usage of PostgreSQL processes
    $cpuOutput = [];
    exec("ps aux | grep postgres | grep -v grep | awk '{cpu_sum += $3} END {print cpu_sum}'", $cpuOutput, $cpuExitCode);
    $cpuUsage = ($cpuExitCode === 0 && !empty($cpuOutput)) ? (float)trim($cpuOutput[0]) : 0;
    
    // Get memory usage of PostgreSQL processes
    $memOutput = [];
    exec("ps aux | grep postgres | grep -v grep | awk '{mem_sum += $4} END {print mem_sum}'", $memOutput, $memExitCode);
    $memoryUsage = ($memExitCode === 0 && !empty($memOutput)) ? (float)trim($memOutput[0]) : 0;
    
    // Get disk I/O (this is a simplification, real-world monitoring would be more complex)
    $diskOutput = [];
    exec("iostat -d | grep -A 1 'Device' | awk 'NR==2 {print $2}'", $diskOutput, $diskExitCode);
    $diskIO = ($diskExitCode === 0 && !empty($diskOutput)) ? (float)trim($diskOutput[0]) : 0;
    
    // Get maximum connections setting
    $maxConnOutput = [];
    exec('su - postgres -c "psql -t -c \"SHOW max_connections;\""', $maxConnOutput, $maxConnExitCode);
    $maxConnections = ($maxConnExitCode === 0 && !empty($maxConnOutput)) ? (int)trim($maxConnOutput[0]) : 100;
    
    // Get current connection count
    $connOutput = [];
    exec('su - postgres -c "psql -t -c \"SELECT COUNT(*) FROM pg_stat_activity;\""', $connOutput, $connExitCode);
    $connectionsUsed = ($connExitCode === 0 && !empty($connOutput)) ? (int)trim($connOutput[0]) : 0;
    
    return [
        'cpu_usage' => $cpuUsage,
        'memory_usage' => $memoryUsage,
        'disk_io' => $diskIO,
        'max_connections' => $maxConnections,
        'connections_used' => $connectionsUsed
    ];
}

/**
 * Get PostgreSQL statistics
 * 
 * @return array|bool Array of statistics or false on failure
 */
function get_postgresql_stats() {
    // Check if PostgreSQL is running
    $output = [];
    $exitCode = 0;
    exec('systemctl is-active postgresql', $output, $exitCode);
    $running = ($exitCode === 0 && trim($output[0]) === 'active');
    
    if (!$running) {
        return false;
    }
    
    // Get cache hit ratio
    $cacheOutput = [];
    exec('su - postgres -c "psql -t -c \"SELECT round(sum(blks_hit) * 100 / (sum(blks_hit) + sum(blks_read)), 2) FROM pg_stat_database WHERE blks_read > 0;\""', $cacheOutput, $cacheExitCode);
    $cacheHitRatio = ($cacheExitCode === 0 && !empty($cacheOutput)) ? (float)trim($cacheOutput[0]) : null;
    
    // Get total database size
    $sizeOutput = [];
    exec('su - postgres -c "psql -t -c \"SELECT pg_size_pretty(sum(pg_database_size(datname))) FROM pg_database;\""', $sizeOutput, $sizeExitCode);
    $totalSize = ($sizeExitCode === 0 && !empty($sizeOutput)) ? trim($sizeOutput[0]) : 'Unknown';
    
    // Get active connections
    $connOutput = [];
    exec('su - postgres -c "psql -t -c \"SELECT COUNT(*) FROM pg_stat_activity WHERE state = \'active\';\""', $connOutput, $connExitCode);
    $activeConnections = ($connExitCode === 0 && !empty($connOutput)) ? (int)trim($connOutput[0]) : 0;
    
    // Get transactions per second (approximate using xact_commit)
    $xactOutput = [];
    exec('su - postgres -c "psql -t -c \"SELECT SUM(xact_commit) / (extract(epoch from (now() - pg_postmaster_start_time()))::numeric) FROM pg_stat_database;\""', $xactOutput, $xactExitCode);
    $transactionsPerSecond = ($xactExitCode === 0 && !empty($xactOutput)) ? (float)trim($xactOutput[0]) : 0;
    
    // Get index usage ratio
    $indexOutput = [];
    exec('su - postgres -c "psql -t -c \"SELECT SUM(idx_scan) / (SUM(idx_scan) + SUM(seq_scan)) * 100 FROM pg_stat_user_tables WHERE (idx_scan + seq_scan) > 0;\""', $indexOutput, $indexExitCode);
    $indexUsage = ($indexExitCode === 0 && !empty($indexOutput)) ? (float)trim($indexOutput[0]) : null;
    
    // Get uptime
    $uptimeOutput = [];
    exec('su - postgres -c "psql -t -c \"SELECT pg_postmaster_start_time();\""', $uptimeOutput, $uptimeExitCode);
    $startTime = ($uptimeExitCode === 0 && !empty($uptimeOutput)) ? strtotime(trim($uptimeOutput[0])) : 0;
    $uptime = $startTime > 0 ? format_uptime(time() - $startTime) : 'Unknown';
    
    return [
        'cache_hit_ratio' => $cacheHitRatio,
        'total_size' => $totalSize,
        'active_connections' => $activeConnections,
        'transactions_per_second' => $transactionsPerSecond,
        'index_usage' => $indexUsage,
        'uptime' => $uptime
    ];
}

/**
 * Get active PostgreSQL connections
 * 
 * @return array|bool Array of active connections or false on failure
 */
function get_active_connections() {
    // Check if PostgreSQL is running
    $output = [];
    $exitCode = 0;
    exec('systemctl is-active postgresql', $output, $exitCode);
    
    if ($exitCode !== 0 || trim($output[0]) !== 'active') {
        return false;
    }
    
    // Get active connections
    $connOutput = [];
    exec('su - postgres -c "psql -t -c \"SELECT datname as database, usename as user, client_addr, application_name, state, EXTRACT(EPOCH FROM (now() - state_change))::integer as seconds_in_state FROM pg_stat_activity WHERE state != \'idle\' ORDER BY seconds_in_state DESC;\""', $connOutput, $connExitCode);
    
    if ($connExitCode !== 0) {
        return false;
    }
    
    $connections = [];
    foreach ($connOutput as $line) {
        $line = trim($line);
        if (!empty($line)) {
            $parts = preg_split('/\|/', $line);
            if (count($parts) >= 6) {
                $seconds = (int)trim($parts[5]);
                $duration = format_duration($seconds);
                
                $connections[] = [
                    'database' => trim($parts[0]),
                    'user' => trim($parts[1]),
                    'client_addr' => trim($parts[2]),
                    'application_name' => trim($parts[3]),
                    'state' => trim($parts[4]),
                    'query_duration' => $duration
                ];
            }
        }
    }
    
    return $connections;
}

/**
 * Get PostgreSQL logs
 * 
 * @return string|bool Log content or false on failure
 */
function get_postgresql_logs() {
    // Check if PostgreSQL is running
    $output = [];
    $exitCode = 0;
    exec('systemctl is-active postgresql', $output, $exitCode);
    
    if ($exitCode !== 0 || trim($output[0]) !== 'active') {
        return false;
    }
    
    // Get log directory
    $logDirOutput = [];
    exec('su - postgres -c "psql -t -c \"SHOW log_directory;\""', $logDirOutput, $logDirExitCode);
    
    if ($logDirExitCode !== 0 || empty($logDirOutput)) {
        return false;
    }
    
    $logDir = trim($logDirOutput[0]);
    
    // Get data directory
    $dataDirOutput = [];
    exec('su - postgres -c "psql -t -c \"SHOW data_directory;\""', $dataDirOutput, $dataDirExitCode);
    
    if ($dataDirExitCode !== 0 || empty($dataDirOutput)) {
        return false;
    }
    
    $dataDir = trim($dataDirOutput[0]);
    
    // Construct full log path
    $logPath = $logDir;
    if ($logDir[0] !== '/') {
        // Relative path to data directory
        $logPath = $dataDir . '/' . $logDir;
    }
    
    // Find the most recent log file
    $logFiles = [];
    exec('ls -t ' . escapeshellarg($logPath) . '/*.log 2>/dev/null', $logFiles, $lsExitCode);
    
    if ($lsExitCode !== 0 || empty($logFiles)) {
        // Try common system log locations as fallback
        $systemLogs = [
            '/var/log/postgresql/postgresql.log',
            '/var/log/postgresql/postgresql-main.log',
            '/var/log/postgresql/postgresql-*.log'
        ];
        
        foreach ($systemLogs as $logPattern) {
            exec('ls -t ' . $logPattern . ' 2>/dev/null | head -1', $fallbackFiles, $fallbackExitCode);
            if ($fallbackExitCode === 0 && !empty($fallbackFiles)) {
                $logFiles = $fallbackFiles;
                break;
            }
        }
        
        if (empty($logFiles)) {
            return "No PostgreSQL log files found.";
        }
    }
    
    $logFile = $logFiles[0];
    
    // Get the tail of the log file
    $logContent = [];
    exec('tail -n 500 ' . escapeshellarg($logFile) . ' 2>/dev/null', $logContent, $tailExitCode);
    
    if ($tailExitCode !== 0) {
        return false;
    }
    
    return implode("\n", $logContent);
}

/**
 * Control PostgreSQL service
 * 
 * @param string $action Action to perform (start, stop, restart, reload)
 * @return bool|string True on success, error message on failure
 */
function control_postgresql_service($action) {
    // Map action to postgres_control.sh command
    $command = '';
    switch ($action) {
        case 'start':
        case 'stop':
        case 'restart':
            $command = $action;
            break;
        case 'reload':
            // For reload, we'll restart PostgreSQL to apply changes
            $command = 'restart';
            break;
        default:
            return "Invalid action: $action";
    }
    
    // Execute the command
    $output = [];
    $exitCode = 0;
    exec(dirname(__FILE__) . '/../../exec/postgres_control.sh ' . escapeshellarg($command), $output, $exitCode);
    
    if ($exitCode !== 0) {
        return "Error executing command: " . implode("\n", $output);
    }
    
    return true;
}

/**
 * Get PostgreSQL settings for a specific category
 * 
 * @param string $category Settings category
 * @return array|bool Array of settings or false on failure
 */
function get_postgresql_settings($category) {
    // Check if PostgreSQL is running
    $output = [];
    $exitCode = 0;
    exec('systemctl is-active postgresql', $output, $exitCode);
    
    if ($exitCode !== 0 || trim($output[0]) !== 'active') {
        return false;
    }
    
    // Define which settings to retrieve for each category
    $settings = [];
    switch ($category) {
        case 'general':
            $params = ['listen_addresses', 'port', 'max_connections', 'timezone'];
            break;
        case 'performance':
            $params = ['shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size'];
            break;
        case 'security':
            $params = ['ssl', 'ssl_cert_file', 'ssl_key_file', 'password_encryption'];
            break;
        case 'backup':
            // These settings might not be in postgresql.conf, so we'll use a dummy approach
            return [
                'backup_directory' => '/var/backups/directadmin/postgresql',
                'backup_retention' => '7',
                'backup_compression' => 'gzip',
                'scheduled_backups' => false,
                'backup_frequency' => 'daily',
                'backup_time' => '03:00'
            ];
        default:
            return false;
    }
    
    // Retrieve each parameter
    foreach ($params as $param) {
        $paramOutput = [];
        exec('su - postgres -c "psql -t -c \"SHOW ' . $param . ';\""', $paramOutput, $paramExitCode);
        
        if ($paramExitCode === 0 && !empty($paramOutput)) {
            $settings[$param] = trim($paramOutput[0]);
        } else {
            $settings[$param] = '';
        }
    }
    
    return $settings;
}

/**
 * Save PostgreSQL settings
 * 
 * @param string $category Settings category
 * @param array $settings Settings to save
 * @return bool|string True on success, error message on failure
 */
function save_postgresql_settings($category, $settings) {
    // Define which settings to save for each category
    $validParams = [];
    switch ($category) {
        case 'general':
            $validParams = ['listen_addresses', 'port', 'max_connections', 'timezone'];
            break;
        case 'performance':
            $validParams = ['shared_buffers', 'work_mem', 'maintenance_work_mem', 'effective_cache_size'];
            break;
        case 'security':
            $validParams = ['ssl', 'ssl_cert_file', 'ssl_key_file', 'password_encryption'];
            break;
        case 'backup':
            // Save backup settings to a custom config file
            return save_backup_settings($settings);
        default:
            return "Invalid category: $category";
    }
    
    // Save each parameter
    $errors = [];
    foreach ($settings as $param => $value) {
        if (in_array($param, $validParams)) {
            $result = set_postgresql_parameter($param, $value);
            if ($result !== true) {
                $errors[] = "Failed to set $param: $result";
            }
        }
    }
    
    if (!empty($errors)) {
        return implode("\n", $errors);
    }
    
    return true;
}

/**
 * Save backup settings
 * 
 * @param array $settings Backup settings
 * @return bool|string True on success, error message on failure
 */
function save_backup_settings($settings) {
    // In a real implementation, you would save these to a config file
    // For this example, we'll just return success
    return true;
}

/**
 * Set a PostgreSQL parameter
 * 
 * @param string $name Parameter name
 * @param string $value Parameter value
 * @return bool|string True on success, error message on failure
 */
function set_postgresql_parameter($name, $value) {
    // Use update_config.sh script to set the parameter
    $output = [];
    $exitCode = 0;
    exec(dirname(__FILE__) . '/../../exec/update_config.sh set_param ' . escapeshellarg($name) . ' ' . escapeshellarg($value), $output, $exitCode);
    
    if ($exitCode !== 0) {
        return "Error setting parameter: " . implode("\n", $output);
    }
    
    return true;
}

/**
 * Delete (reset to default) a PostgreSQL parameter
 * 
 * @param string $name Parameter name
 * @return bool|string True on success, error message on failure
 */
function delete_postgresql_parameter($name) {
    // Get the PostgreSQL data directory
    $dataDirOutput = [];
    exec('su - postgres -c "psql -t -c \"SHOW data_directory;\""', $dataDirOutput, $dataDirExitCode);
    
    if ($dataDirExitCode !== 0 || empty($dataDirOutput)) {
        return "Failed to determine PostgreSQL data directory";
    }
    
    $dataDir = trim($dataDirOutput[0]);
    $confFile = "$dataDir/postgresql.conf";
    
    // Comment out the parameter in postgresql.conf
    $output = [];
    $exitCode = 0;
    exec("sed -i 's/^[[:space:]]*" . $name . "[[:space:]]*=/#" . $name . "=/g' " . escapeshellarg($confFile), $output, $exitCode);
    
    if ($exitCode !== 0) {
        return "Error modifying configuration file: " . implode("\n", $output);
    }
    
    // Reload the configuration
    $reloadOutput = [];
    $reloadExitCode = 0;
    exec(dirname(__FILE__) . '/../../exec/postgres_control.sh reload', $reloadOutput, $reloadExitCode);
    
    if ($reloadExitCode !== 0) {
        return "Error reloading configuration: " . implode("\n", $reloadOutput);
    }
    
    return true;
}

/**
 * Get custom PostgreSQL parameters
 * 
 * @return array|bool Array of custom parameters or false on failure
 */
function get_custom_parameters() {
    // Get the PostgreSQL data directory
    $dataDirOutput = [];
    exec('su - postgres -c "psql -t -c \"SHOW data_directory;\""', $dataDirOutput, $dataDirExitCode);
    
    if ($dataDirExitCode !== 0 || empty($dataDirOutput)) {
        return false;
    }
    
    $dataDir = trim($dataDirOutput[0]);
    $confFile = "$dataDir/postgresql.conf";
    
    // Get non-commented parameters from postgresql.conf
    $output = [];
    $exitCode = 0;
    exec("grep -v '^[[:space:]]*#' " . escapeshellarg($confFile) . " | grep '=' | sed 's/[[:space:]]*=[[:space:]]*/=/'", $output, $exitCode);
    
    if ($exitCode !== 0) {
        return false;
    }
    
    $parameters = [];
    foreach ($output as $line) {
        $line = trim($line);
        if (!empty($line)) {
            $parts = explode('=', $line, 2);
            if (count($parts) === 2) {
                $name = trim($parts[0]);
                $value = trim($parts[1]);
                
                // Remove trailing comments if any
                $value = preg_replace('/#.*$/', '', $value);
                $value = trim($value);
                
                // Remove quotes if present
                $value = trim($value, "'\"");
                
                $parameters[] = [
                    'name' => $name,
                    'value' => $value
                ];
            }
        }
    }
    
    return $parameters;
}

/**
 * Get the content of a PostgreSQL configuration file
 * 
 * @param string $filename Configuration filename
 * @return string|bool File content or false on failure
 */
function get_config_file_content($filename) {
    // Get the PostgreSQL data directory
    $dataDirOutput = [];
    exec('su - postgres -c "psql -t -c \"SHOW data_directory;\""', $dataDirOutput, $dataDirExitCode);
    
    if ($dataDirExitCode !== 0 || empty($dataDirOutput)) {
        return false;
    }
    
    $dataDir = trim($dataDirOutput[0]);
    $filePath = "$dataDir/$filename";
    
    // Check if the file exists
    if (!file_exists($filePath)) {
        return "File not found: $filePath";
    }
    
    // Read the file content
    $content = file_get_contents($filePath);
    if ($content === false) {
        return false;
    }
    
    return $content;
}

// The format_uptime and format_duration functions are now defined in includes/functions.php
