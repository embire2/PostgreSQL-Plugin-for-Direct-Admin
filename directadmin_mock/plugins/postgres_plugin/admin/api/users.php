<?php
/**
 * PostgreSQL Admin API - Users
 * 
 * This file handles all user-related API requests for the admin panel
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
    case 'list':
        // List all PostgreSQL users
        $users = get_all_pg_users();
        if ($users !== false) {
            $response = [
                'status' => 'success',
                'data' => $users
            ];
        } else {
            $response['message'] = 'Failed to retrieve PostgreSQL users';
        }
        break;
        
    case 'list_da_users':
        // List all DirectAdmin users
        $users = get_directadmin_users();
        if ($users !== false) {
            $response = [
                'status' => 'success',
                'data' => $users
            ];
        } else {
            $response['message'] = 'Failed to retrieve DirectAdmin users';
        }
        break;
        
    case 'create':
        // Create a new PostgreSQL user
        if (isset($_POST['username']) && isset($_POST['password'])) {
            $username = trim($_POST['username']);
            $password = $_POST['password'];
            $linkedUser = isset($_POST['linked_user']) ? trim($_POST['linked_user']) : '';
            
            // Validate username
            if (!preg_match('/^[a-zA-Z0-9_]+$/', $username)) {
                $response['message'] = 'Invalid username. Use only letters, numbers and underscores.';
                break;
            }
            
            // Execute the create_user.sh script
            $result = exec_script('create_user.sh', [$username, $password], $output);
            
            if ($result === 0) {
                // If linked to a DirectAdmin user, store that information
                if (!empty($linkedUser)) {
                    // In a real implementation, you would store this link in a database or config file
                    // Here we'll just acknowledge it in the response
                    $response = [
                        'status' => 'success',
                        'message' => "User $username created successfully and linked to DirectAdmin user $linkedUser",
                        'data' => ['username' => $username, 'linked_to' => $linkedUser]
                    ];
                } else {
                    $response = [
                        'status' => 'success',
                        'message' => "User $username created successfully",
                        'data' => ['username' => $username]
                    ];
                }
            } else {
                $response['message'] = 'Failed to create user: ' . implode("\n", $output);
            }
        } else {
            $response['message'] = 'Missing required parameters';
        }
        break;
        
    case 'update':
        // Update a PostgreSQL user (currently only supports password changes)
        if (isset($_POST['username'])) {
            $username = trim($_POST['username']);
            $password = isset($_POST['password']) ? $_POST['password'] : '';
            
            if (!empty($password)) {
                // Execute the create_user.sh script with the same username to update the password
                $result = exec_script('create_user.sh', [$username, $password], $output);
                
                if ($result === 0) {
                    $response = [
                        'status' => 'success',
                        'message' => "User $username updated successfully"
                    ];
                } else {
                    $response['message'] = 'Failed to update user: ' . implode("\n", $output);
                }
            } else {
                $response = [
                    'status' => 'success',
                    'message' => "No changes were made to user $username"
                ];
            }
        } else {
            $response['message'] = 'Missing username parameter';
        }
        break;
        
    case 'delete':
        // Delete a PostgreSQL user
        if (isset($_POST['username'])) {
            $username = trim($_POST['username']);
            $deleteDBs = isset($_POST['delete_databases']) && ($_POST['delete_databases'] === 'true' || $_POST['delete_databases'] === true);
            
            // First, if requested, delete all databases owned by this user
            if ($deleteDBs) {
                $databases = get_user_databases($username);
                if ($databases !== false) {
                    foreach ($databases as $db) {
                        if ($db['owner'] === $username) {
                            exec_script('delete_database.sh', [$db['name']], $dbOutput);
                        }
                    }
                }
            }
            
            // Now delete the user
            $result = exec_script('delete_user.sh', [$username], $output);
            
            if ($result === 0) {
                $response = [
                    'status' => 'success',
                    'message' => "User $username deleted successfully" . ($deleteDBs ? " along with owned databases" : "")
                ];
            } else {
                $response['message'] = 'Failed to delete user: ' . implode("\n", $output);
            }
        } else {
            $response['message'] = 'Missing username parameter';
        }
        break;
        
    case 'sync_da_users':
        // Synchronize PostgreSQL users with DirectAdmin users
        $daUsers = get_directadmin_users();
        $pgUsers = get_all_pg_users();
        
        if ($daUsers === false || $pgUsers === false) {
            $response['message'] = 'Failed to retrieve user lists';
            break;
        }
        
        // Create a map of existing PostgreSQL users for quick lookup
        $pgUserMap = [];
        foreach ($pgUsers as $user) {
            $pgUserMap[$user['username']] = true;
        }
        
        // Track results
        $created = 0;
        $skipped = 0;
        $errors = [];
        
        // For each DirectAdmin user, create a PostgreSQL user if it doesn't exist
        foreach ($daUsers as $user) {
            $daUsername = $user['username'];
            
            if (!isset($pgUserMap[$daUsername])) {
                // Generate a random password
                $password = generate_random_password();
                
                // Create the PostgreSQL user
                $result = exec_script('create_user.sh', [$daUsername, $password], $output);
                
                if ($result === 0) {
                    $created++;
                    
                    // Store the password in the user's home directory
                    $userHome = "/home/$daUsername";
                    if (is_dir($userHome)) {
                        $pgInfoFile = "$userHome/.postgresql_credentials";
                        file_put_contents($pgInfoFile, "PostgreSQL Username: $daUsername\nPostgreSQL Password: $password");
                        chmod($pgInfoFile, 0600);
                        chown($pgInfoFile, $daUsername);
                        chgrp($pgInfoFile, $daUsername);
                    }
                } else {
                    $errors[] = "Failed to create user $daUsername: " . implode("\n", $output);
                }
            } else {
                $skipped++;
            }
        }
        
        if (empty($errors)) {
            $response = [
                'status' => 'success',
                'message' => "Synchronization completed. Created $created new users, skipped $skipped existing users."
            ];
        } else {
            $response = [
                'status' => 'partial',
                'message' => "Synchronization partially completed. Created $created new users, skipped $skipped existing users. Encountered " . count($errors) . " errors.",
                'errors' => $errors
            ];
        }
        break;
        
    case 'count':
        // Get user count
        $count = get_pg_user_count();
        if ($count !== false) {
            $response = [
                'status' => 'success',
                'data' => ['count' => $count]
            ];
        } else {
            $response['message'] = 'Failed to count PostgreSQL users';
        }
        break;
        
    case 'user_databases':
        // Get databases accessible by a specific user
        if (isset($_GET['username'])) {
            $username = trim($_GET['username']);
            $databases = get_user_databases($username);
            
            if ($databases !== false) {
                $response = [
                    'status' => 'success',
                    'data' => $databases
                ];
            } else {
                $response['message'] = "Failed to retrieve databases for user $username";
            }
        } else {
            $response['message'] = 'Missing username parameter';
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
 * Get a list of all DirectAdmin users
 * 
 * @return array|bool Array of DirectAdmin user information or false on failure
 */
function get_directadmin_users() {
    $usersFile = '/usr/local/directadmin/data/users/users.list';
    
    if (!file_exists($usersFile)) {
        return false;
    }
    
    $content = file_get_contents($usersFile);
    if ($content === false) {
        return false;
    }
    
    $usernames = explode("\n", trim($content));
    $users = [];
    
    foreach ($usernames as $username) {
        $username = trim($username);
        if (!empty($username)) {
            $users[] = [
                'username' => $username,
                'type' => 'user' // In a real implementation, you might determine if they're admin, reseller, etc.
            ];
        }
    }
    
    return $users;
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
 * Get a count of PostgreSQL users
 * 
 * @return int|bool Count of users or false on failure
 */
function get_pg_user_count() {
    $output = [];
    $exitCode = 0;
    
    // Count users that can login
    exec('su - postgres -c "psql -t -c \"SELECT COUNT(*) FROM pg_catalog.pg_roles WHERE rolcanlogin = true AND rolname NOT IN (\'postgres\');\""', $output, $exitCode);
    
    if ($exitCode !== 0 || empty($output)) {
        return false;
    }
    
    return (int)trim($output[0]);
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
 * Get databases accessible by a specific user
 * 
 * @param string $username Username to check
 * @return array|bool Array of database information or false on failure
 */
function get_user_databases($username) {
    $output = [];
    $exitCode = 0;
    
    // Get databases owned by the user
    exec('su - postgres -c "psql -t -c \"SELECT d.datname, pg_catalog.pg_get_userbyid(d.datdba) as owner, pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname)) as size FROM pg_catalog.pg_database d JOIN pg_catalog.pg_roles r ON d.datdba = r.oid WHERE r.rolname = \'' . pg_escape_literal($username) . '\' OR pg_has_role(\'' . pg_escape_literal($username) . '\', d.datdba, \'MEMBER\') ORDER BY d.datname;\""', $output, $exitCode);
    
    if ($exitCode !== 0) {
        return false;
    }
    
    $databases = [];
    foreach ($output as $line) {
        $line = trim($line);
        if (!empty($line)) {
            $parts = preg_split('/\|/', $line);
            if (count($parts) >= 3) {
                $dbname = trim($parts[0]);
                $owner = trim($parts[1]);
                
                // Skip system databases
                if (in_array($dbname, ['postgres', 'template0', 'template1'])) {
                    continue;
                }
                
                // Get privileges
                $privileges = 'UNKNOWN';
                if ($owner === $username) {
                    $privileges = 'ALL (owner)';
                } else {
                    $privOutput = [];
                    exec('su - postgres -c "psql -t -d ' . $dbname . ' -c \"SELECT privilege_type FROM information_schema.role_usage_grants WHERE grantee = \'' . pg_escape_literal($username) . '\';\""', $privOutput, $privExitCode);
                    if ($privExitCode === 0 && !empty($privOutput)) {
                        $privileges = implode(', ', array_map('trim', $privOutput));
                    }
                }
                
                $databases[] = [
                    'name' => $dbname,
                    'owner' => $owner,
                    'size' => trim($parts[2]),
                    'privileges' => $privileges
                ];
            }
        }
    }
    
    return $databases;
}

// The pg_escape_literal and exec_script functions are now defined in includes/functions.php

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
