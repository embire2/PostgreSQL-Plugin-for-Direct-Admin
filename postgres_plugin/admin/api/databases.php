<?php
/**
 * PostgreSQL Admin API - Databases
 * 
 * This file handles all database-related API requests for the admin panel
 */

// Initialize session and check admin permissions
session_start();
require_once(dirname(__FILE__) . '/../../../scripts/check_admin_auth.php');

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
    case 'list':
        // List all databases
        $databases = get_all_databases();
        if ($databases !== false) {
            $response = [
                'status' => 'success',
                'data' => $databases
            ];
        } else {
            $response['message'] = 'Failed to retrieve databases';
        }
        break;
        
    case 'create':
        // Create a new database
        if (isset($_POST['name']) && isset($_POST['owner'])) {
            $name = trim($_POST['name']);
            $owner = trim($_POST['owner']);
            
            // Validate database name
            if (!preg_match('/^[a-zA-Z0-9_]+$/', $name)) {
                $response['message'] = 'Invalid database name. Use only letters, numbers and underscores.';
                break;
            }
            
            // Execute the create_database.sh script
            $result = exec_script('create_database.sh', [$name, $owner], $output);
            
            if ($result === 0) {
                $response = [
                    'status' => 'success',
                    'message' => "Database $name created successfully",
                    'data' => ['name' => $name, 'owner' => $owner]
                ];
            } else {
                $response['message'] = 'Failed to create database: ' . implode("\n", $output);
            }
        } else {
            $response['message'] = 'Missing required parameters';
        }
        break;
        
    case 'delete':
        // Delete a database
        if (isset($_POST['name'])) {
            $name = trim($_POST['name']);
            
            // Execute the delete_database.sh script
            $result = exec_script('delete_database.sh', [$name], $output);
            
            if ($result === 0) {
                $response = [
                    'status' => 'success',
                    'message' => "Database $name deleted successfully"
                ];
            } else {
                $response['message'] = 'Failed to delete database: ' . implode("\n", $output);
            }
        } else {
            $response['message'] = 'Missing database name parameter';
        }
        break;
        
    case 'assign_user':
        // Assign a user to a database
        if (isset($_POST['database']) && isset($_POST['username'])) {
            $database = trim($_POST['database']);
            $username = trim($_POST['username']);
            $privileges = isset($_POST['privileges']) ? trim($_POST['privileges']) : 'ALL';
            
            // Execute the assign_user.sh script
            $result = exec_script('assign_user.sh', [$database, $username, $privileges], $output);
            
            if ($result === 0) {
                $response = [
                    'status' => 'success',
                    'message' => "User $username assigned to database $database with $privileges privileges"
                ];
            } else {
                $response['message'] = 'Failed to assign user: ' . implode("\n", $output);
            }
        } else {
            $response['message'] = 'Missing required parameters';
        }
        break;
        
    case 'backup':
        // Backup databases
        $backupType = isset($_POST['type']) ? $_POST['type'] : 'all';
        $database = isset($_POST['database']) ? trim($_POST['database']) : null;
        
        if ($backupType === 'all') {
            // Backup all databases
            $result = exec_script('postgres_backup.sh', ['backup_all'], $output);
        } else {
            // Backup a specific database
            if (empty($database)) {
                $response['message'] = 'Missing database parameter for backup';
                break;
            }
            $result = exec_script('postgres_backup.sh', ['backup_db', $database], $output);
        }
        
        if ($result === 0) {
            $response = [
                'status' => 'success',
                'message' => "Backup completed successfully. " . implode("\n", $output)
            ];
        } else {
            $response['message'] = 'Backup failed: ' . implode("\n", $output);
        }
        break;
        
    case 'count':
        // Get database count
        $count = get_database_count();
        if ($count !== false) {
            $response = [
                'status' => 'success',
                'data' => ['count' => $count]
            ];
        } else {
            $response['message'] = 'Failed to count databases';
        }
        break;
        
    case 'sizes':
        // Get database sizes for charts
        $sizes = get_database_sizes();
        if ($sizes !== false) {
            $response = [
                'status' => 'success',
                'data' => $sizes
            ];
        } else {
            $response['message'] = 'Failed to retrieve database sizes';
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
 * Get a list of all PostgreSQL databases
 * 
 * @return array|bool Array of database information or false on failure
 */
function get_all_databases() {
    $output = [];
    $exitCode = 0;
    
    // Execute SQL to get database list
    exec('su - postgres -c "psql -t -c \"SELECT d.datname, pg_catalog.pg_get_userbyid(d.datdba) as owner, pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) as size, pg_catalog.pg_encoding_to_char(d.encoding) as encoding, to_char(d.datcollate, \'YYYY-MM-DD HH24:MI:SS\') as created FROM pg_catalog.pg_database d WHERE d.datistemplate = false ORDER BY d.datname;\""', $output, $exitCode);
    
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
 * Get a count of PostgreSQL databases
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
 * Get sizes of all databases for charts
 * 
 * @return array|bool Array of database sizes or false on failure
 */
function get_database_sizes() {
    $output = [];
    $exitCode = 0;
    
    // Get database sizes in bytes
    exec('su - postgres -c "psql -t -c \"SELECT d.datname, pg_catalog.pg_database_size(d.datname) FROM pg_catalog.pg_database d WHERE d.datistemplate = false ORDER BY pg_catalog.pg_database_size(d.datname) DESC;\""', $output, $exitCode);
    
    if ($exitCode !== 0) {
        return false;
    }
    
    $sizes = [];
    foreach ($output as $line) {
        $line = trim($line);
        if (!empty($line)) {
            $parts = preg_split('/\|/', $line);
            if (count($parts) >= 2) {
                $sizes[] = [
                    'name' => trim($parts[0]),
                    'size_bytes' => (int)trim($parts[1])
                ];
            }
        }
    }
    
    return $sizes;
}

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
    $scriptsDir = dirname(__FILE__) . '/../../scripts/';
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
