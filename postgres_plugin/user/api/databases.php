<?php
/**
 * PostgreSQL User API - Databases
 * 
 * This file handles all database-related API requests for the user panel
 */

// Initialize session and check user permissions
session_start();
require_once(dirname(__FILE__) . '/../../../scripts/check_user_auth.php');

// Set content type to JSON
header('Content-Type: application/json');

// Include necessary functions
require_once(dirname(__FILE__) . '/../../includes/functions.php');

// Get the logged in username from DirectAdmin
$username = getDirectAdminUsername();

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
        // List databases for the current user
        $databases = get_user_databases($username);
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
        // Create a new database for the current user
        if (isset($_POST['name'])) {
            $name = trim($_POST['name']);
            
            // Validate database name
            if (!preg_match('/^[a-zA-Z0-9_]+$/', $name)) {
                $response['message'] = 'Invalid database name. Use only letters, numbers and underscores.';
                break;
            }
            
            // Prefix the database name with the username for uniqueness and security
            $fullDatabaseName = $username . '_' . $name;
            
            // Execute the create_database.sh script
            $result = exec_script('create_database.sh', [$fullDatabaseName, $username], $output);
            
            if ($result === 0) {
                $response = [
                    'status' => 'success',
                    'message' => "Database $name created successfully",
                    'data' => ['name' => $fullDatabaseName, 'owner' => $username]
                ];
            } else {
                $response['message'] = 'Failed to create database: ' . implode("\n", $output);
            }
        } else {
            $response['message'] = 'Missing database name parameter';
        }
        break;
        
    case 'delete':
        // Delete a database (only if owned by the current user)
        if (isset($_POST['name'])) {
            $name = trim($_POST['name']);
            
            // Verify the user owns this database
            $ownedDatabases = get_user_owned_databases($username);
            $hasAccess = false;
            
            foreach ($ownedDatabases as $db) {
                if ($db['name'] === $name) {
                    $hasAccess = true;
                    break;
                }
            }
            
            if (!$hasAccess) {
                $response['message'] = 'You do not have permission to delete this database';
                break;
            }
            
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
        
    case 'backup':
        // Backup databases owned by the current user
        $backupType = isset($_POST['type']) ? $_POST['type'] : 'all';
        $database = isset($_POST['database']) ? trim($_POST['database']) : null;
        
        // If backing up a specific database, verify it belongs to the user
        if ($backupType === 'selected' && !empty($database)) {
            $ownedDatabases = get_user_owned_databases($username);
            $hasAccess = false;
            
            foreach ($ownedDatabases as $db) {
                if ($db['name'] === $database) {
                    $hasAccess = true;
                    break;
                }
            }
            
            if (!$hasAccess) {
                $response['message'] = 'You do not have permission to backup this database';
                break;
            }
            
            // Backup the specific database
            $result = exec_script('postgres_backup.sh', ['backup_db', $database], $output);
        } else {
            // Backup all databases owned by the user
            // Create a temporary file with the list of databases to backup
            $tempFile = tempnam(sys_get_temp_dir(), 'pg_backup_');
            $ownedDatabases = get_user_owned_databases($username);
            $dbList = '';
            
            foreach ($ownedDatabases as $db) {
                $dbList .= $db['name'] . "\n";
            }
            
            file_put_contents($tempFile, $dbList);
            
            // Use a custom backup command for multiple specific databases
            $result = exec_script('postgres_backup.sh', ['backup_db_list', $tempFile], $output);
            
            // Clean up
            unlink($tempFile);
        }
        
        if ($result === 0) {
            $backupPath = '/var/backups/directadmin/postgresql/' . date('Y-m-d-His');
            $response = [
                'status' => 'success',
                'message' => "Backup completed successfully. Your database backups are stored in $backupPath"
            ];
        } else {
            $response['message'] = 'Backup failed: ' . implode("\n", $output);
        }
        break;
        
    case 'stats':
        // Get database statistics for the current user
        $stats = get_user_database_stats($username);
        if ($stats !== false) {
            $response = [
                'status' => 'success',
                'data' => $stats
            ];
        } else {
            $response['message'] = 'Failed to retrieve database statistics';
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
 * Get a list of databases for a user
 * 
 * @param string $username The DirectAdmin username
 * @return array|bool Array of database information or false on failure
 */
function get_user_databases($username) {
    // First get databases owned by the user
    $ownedDatabases = get_user_owned_databases($username);
    
    // Also get databases that the user has access to but doesn't own
    $accessibleDatabases = get_user_accessible_databases($username);
    
    // Combine the lists (remove duplicates)
    $databases = $ownedDatabases;
    foreach ($accessibleDatabases as $db) {
        $found = false;
        foreach ($databases as $existingDb) {
            if ($existingDb['name'] === $db['name']) {
                $found = true;
                break;
            }
        }
        
        if (!$found) {
            $databases[] = $db;
        }
    }
    
    return $databases;
}

/**
 * Get a list of databases owned by a user
 * 
 * @param string $username The DirectAdmin username
 * @return array|bool Array of database information or false on failure
 */
function get_user_owned_databases($username) {
    $output = [];
    $exitCode = 0;
    
    // Execute SQL to get databases owned by the user
    exec('su - postgres -c "psql -t -c \"SELECT d.datname, pg_catalog.pg_get_userbyid(d.datdba) as owner, pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) as size, pg_catalog.pg_encoding_to_char(d.encoding) as encoding, to_char(d.datcreate, \'YYYY-MM-DD HH24:MI:SS\') as created FROM pg_catalog.pg_database d JOIN pg_catalog.pg_roles r ON d.datdba = r.oid WHERE r.rolname = \'' . pg_escape_literal($username) . '\' AND d.datistemplate = false ORDER BY d.datname;\""', $output, $exitCode);
    
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
 * Get a list of databases that a user has access to but doesn't own
 * 
 * @param string $username The DirectAdmin username
 * @return array|bool Array of database information or false on failure
 */
function get_user_accessible_databases($username) {
    $output = [];
    $exitCode = 0;
    
    // Execute SQL to get databases the user has access to but doesn't own
    exec('su - postgres -c "psql -t -c \"SELECT d.datname, pg_catalog.pg_get_userbyid(d.datdba) as owner, pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) as size, pg_catalog.pg_encoding_to_char(d.encoding) as encoding FROM pg_catalog.pg_database d JOIN pg_catalog.pg_roles r ON d.datdba = r.oid WHERE d.datistemplate = false AND EXISTS (SELECT 1 FROM pg_catalog.pg_user u JOIN pg_catalog.pg_auth_members m ON u.usesysid = m.member JOIN pg_catalog.pg_roles r1 ON m.roleid = r1.oid WHERE u.usename = \'' . pg_escape_literal($username) . '\' AND r1.oid = d.datdba) ORDER BY d.datname;\""', $output, $exitCode);
    
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
                    'created' => null
                ];
            }
        }
    }
    
    return $databases;
}

/**
 * Get database statistics for a user
 * 
 * @param string $username The DirectAdmin username
 * @return array|bool Array of statistics or false on failure
 */
function get_user_database_stats($username) {
    // Get databases owned by the user
    $databases = get_user_owned_databases($username);
    
    if ($databases === false) {
        return false;
    }
    
    // Calculate total size
    $totalSize = '0 B';
    $count = count($databases);
    
    if ($count > 0) {
        // Execute SQL to get total size
        $output = [];
        $exitCode = 0;
        exec('su - postgres -c "psql -t -c \"SELECT pg_size_pretty(SUM(pg_database_size(datname))) FROM pg_database d JOIN pg_roles r ON d.datdba = r.oid WHERE r.rolname = \'' . pg_escape_literal($username) . '\';\""', $output, $exitCode);
        
        if ($exitCode === 0 && !empty($output)) {
            $totalSize = trim($output[0]);
        }
    }
    
    return [
        'count' => $count,
        'total_size' => $totalSize
    ];
}

/**
 * Get the current logged in DirectAdmin username
 * 
 * @return string The username
 */
function getDirectAdminUsername() {
    // In a real DirectAdmin plugin, this would get the username from DirectAdmin
    // For this example, we'll use a simplified approach
    
    if (isset($_SESSION['username'])) {
        return $_SESSION['username'];
    }
    
    // Try to get username from environment
    if (isset($_SERVER['REMOTE_USER'])) {
        return $_SERVER['REMOTE_USER'];
    }
    
    // Fallback to getting it from the session cookie
    $sessionId = isset($_COOKIE['session']) ? $_COOKIE['session'] : '';
    if (!empty($sessionId)) {
        $sessionFile = '/usr/local/directadmin/data/sessions/' . $sessionId;
        if (file_exists($sessionFile)) {
            $sessionData = file_get_contents($sessionFile);
            if (preg_match('/username=([^\n]+)/', $sessionData, $matches)) {
                return $matches[1];
            }
        }
    }
    
    // Last resort - return the server user
    $processOwner = posix_getpwuid(posix_geteuid());
    return $processOwner['name'];
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
