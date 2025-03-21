<?php
/**
 * PostgreSQL User API - Status
 * 
 * This file handles status information and user credentials for the user panel
 */

// Initialize session and check user permissions
session_start();
require_once(dirname(__FILE__) . '/../../scripts/check_user_auth.php');

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
        
    case 'credentials':
        // Get PostgreSQL credentials for the logged in user
        $credentials = get_user_credentials($username);
        if ($credentials !== false) {
            $response = [
                'status' => 'success',
                'data' => $credentials
            ];
        } else {
            $response['message'] = 'Failed to retrieve PostgreSQL credentials';
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
    
    // Get host and port information (simplified for direct users)
    $host = 'localhost';
    $port = '5432';
    
    // Try to get actual port from configuration
    if ($running) {
        $portOutput = [];
        exec('su - postgres -c "psql -t -c \"SHOW port;\""', $portOutput, $portExitCode);
        if ($portExitCode === 0 && !empty($portOutput)) {
            $port = trim($portOutput[0]);
        }
    }
    
    return [
        'running' => $running,
        'version' => $version,
        'host' => $host,
        'port' => $port
    ];
}

/**
 * Get PostgreSQL credentials for a user
 * 
 * @param string $username The DirectAdmin username
 * @return array|bool Array of credentials or false on failure
 */
function get_user_credentials($username) {
    // Check if the PostgreSQL user exists
    $output = [];
    $exitCode = 0;
    exec('su - postgres -c "psql -t -c \"SELECT 1 FROM pg_roles WHERE rolname = \'' . pg_escape_literal($username) . '\';\""', $output, $exitCode);
    
    $userExists = ($exitCode === 0 && !empty($output) && trim($output[0]) === '1');
    
    if (!$userExists) {
        // User doesn't exist, return error
        return false;
    }
    
    // Check if the credentials file exists in user's home directory
    $credentialsFile = "/home/$username/.postgresql_credentials";
    $password = '';
    
    if (file_exists($credentialsFile)) {
        $credentialsContent = file_get_contents($credentialsFile);
        if (preg_match('/PostgreSQL Password: (.+)/', $credentialsContent, $matches)) {
            $password = $matches[1];
        }
    }
    
    // If password not found, return a placeholder message
    if (empty($password)) {
        $password = "Contact your administrator for the password";
    }
    
    return [
        'username' => $username,
        'password' => $password
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

// The pg_escape_literal function is now defined in includes/functions.php
