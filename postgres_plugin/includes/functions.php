<?php
/**
 * Shared functions for the PostgreSQL DirectAdmin plugin
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
 * Escape a literal value for PostgreSQL (if function doesn't already exist)
 * 
 * @param string $value Value to escape
 * @return string Escaped value
 */
if (!function_exists('pg_escape_literal')) {
    function pg_escape_literal($value) {
        // Simple implementation - in a real environment, use built-in pg_escape_literal
        // but for our demo, we'll implement a basic version
        return "'" . str_replace("'", "''", $value) . "'";
    }
}

/**
 * Format a duration in a human-readable format
 * 
 * @param int $seconds Duration in seconds
 * @return string Formatted duration
 */
function format_duration($seconds) {
    if ($seconds < 60) {
        return "$seconds sec";
    } elseif ($seconds < 3600) {
        $minutes = floor($seconds / 60);
        $seconds %= 60;
        return "$minutes min $seconds sec";
    } else {
        $hours = floor($seconds / 3600);
        $seconds %= 3600;
        $minutes = floor($seconds / 60);
        $seconds %= 60;
        return "$hours hr $minutes min $seconds sec";
    }
}

/**
 * Format uptime in a human-readable format
 * 
 * @param int $seconds Uptime in seconds
 * @return string Formatted uptime
 */
function format_uptime($seconds) {
    $days = floor($seconds / 86400);
    $seconds %= 86400;
    
    $hours = floor($seconds / 3600);
    $seconds %= 3600;
    
    $minutes = floor($seconds / 60);
    $seconds %= 60;
    
    $result = '';
    if ($days > 0) {
        $result .= "$days days, ";
    }
    
    $result .= sprintf('%02d:%02d:%02d', $hours, $minutes, $seconds);
    
    return $result;
}

/**
 * Generate a random password with specified length and complexity
 * 
 * @param int $length Password length
 * @param bool $includeSpecial Whether to include special characters
 * @return string Generated password
 */
if (!function_exists('generate_random_password')) {
    function generate_random_password($length = 12, $includeSpecial = true) {
        $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        $special = '!@#$%^&*()-_=+[]{}|;:,.<>?';
        
        if ($includeSpecial) {
            $chars .= $special;
        }
        
        $password = '';
        $charsLength = strlen($chars);
        
        for ($i = 0; $i < $length; $i++) {
            $password .= $chars[rand(0, $charsLength - 1)];
        }
        
        return $password;
    }
}

/**
 * Validate a database name to ensure it contains only allowed characters
 * 
 * @param string $name Database name to validate
 * @return bool True if valid, false otherwise
 */
function is_valid_database_name($name) {
    return preg_match('/^[a-zA-Z0-9_]+$/', $name);
}

/**
 * Validate a username to ensure it contains only allowed characters
 * 
 * @param string $username Username to validate
 * @return bool True if valid, false otherwise
 */
function is_valid_username($username) {
    return preg_match('/^[a-zA-Z0-9_]+$/', $username);
}

/**
 * Format a file size in bytes to a human-readable format
 * 
 * @param int $bytes Size in bytes
 * @param int $decimals Number of decimal places
 * @return string Formatted file size string
 */
function format_bytes($bytes, $decimals = 2) {
    $size = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    $factor = floor((strlen($bytes) - 1) / 3);
    return sprintf("%.{$decimals}f", $bytes / pow(1024, $factor)) . ' ' . $size[$factor];
}
?>