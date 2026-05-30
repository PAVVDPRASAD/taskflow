<!DOCTYPE html>
<html>
<head>
    <title>Error - Task Flow App</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 20px; }
        .error-container { max-width: 600px; margin: 50px auto; background: white; padding: 30px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        h1 { color: #d32f2f; margin-top: 0; }
        p { color: #666; line-height: 1.6; }
        .error-id { background: #f0f0f0; padding: 10px; margin: 15px 0; border-left: 3px solid #d32f2f; font-family: monospace; font-size: 12px; }
        a { color: #1976d2; text-decoration: none; }
        a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <cfoutput>
    <div class="error-container">
        <h1>An Error Occurred</h1>
        <p>We're sorry, but something unexpected happened. Our team has been notified and we're working to fix it.</p>
        <p>Please try one of the following:</p>
        <ul>
            <li><a href="/taskflow/login.cfm">Return to Login</a></li>
            <li><a href="javascript:history.back()">Go Back</a></li>
        </ul>
        <p><small>If the problem persists, please contact support with reference ID: #createUUID()#</small></p>
    </div>
    </cfoutput>
</body>
</html>
