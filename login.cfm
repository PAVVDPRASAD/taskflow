<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">
    <title>Login - TaskFlow</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          rel="stylesheet">
</head>

<body class="bg-dark">
    <div class="container d-flex justify-content-center align-items-center min-vh-100">
        <div class="col-12 col-md-8 col-lg-5">
            <div class="card shadow p-4">
                <h3 class="text-center mb-4">User Login</h3>
                <form id="loginForm">
                    <input type="hidden" id="csrfToken" value="<cfoutput>#session.csrfToken#</cfoutput>">
                    <div class="form-floating mb-3">
                        <input type="text"
                               class="form-control"
                               name="loginID"
                               id="loginID"
                               placeholder="Username or Email"
                               autocomplete="username">
                        <label for="loginID">Username or Email</label>
                    </div>

                    <div class="form-floating mb-3">
                        <input type="password"
                               class="form-control"
                               name="Password"
                               id="loginPassword"
                               placeholder="Password"
                               autocomplete="current-password">
                        <label for="loginPassword">Password</label>
                    </div>
                    <p class="text-end mt-3 mb-2">
                        <a class="text-decoration-none" href="#" id="forgotPasswordLink">Forgot password?</a>
                    </p>

                    <div id="loginError" class="alert alert-danger d-none"></div>

                    <div class="d-grid">
                        <button type="submit" class="btn btn-primary btn-lg">Login</button>
                    </div>
                    
                    <p class="text-center mt-2 mb-0">Don't have an account?
                        <a href="register.cfm" class="text-decoration-none">Register here</a>
                    </p>
                </form>
            </div>
        </div>
    </div>

    <div class="modal fade" id="forgotPasswordModal" tabindex="-1" aria-labelledby="forgotPasswordModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="forgotPasswordModalLabel">Reset Password</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form id="forgotPasswordForm">
                        <div id="forgotPasswordError" class="alert alert-danger d-none"></div>
                        <div id="forgotPasswordSuccess" class="alert alert-success d-none"></div>
                        <div class="mb-3" id="forgotEmailSection">
                            <label for="forgotEmail" class="form-label">Email address</label>
                            <input type="email" class="form-control" id="forgotEmail" placeholder="Enter your registered email">
                        </div>
                        <div id="otpSection" style="display:none;" class="mb-3">
                            <label for="otpInput" class="form-label">Enter OTP</label>
                            <input type="text" class="form-control" id="otpInput" placeholder="Enter the 6-digit OTP">
                        </div>
                        <div id="passwordSection" style="display:none;" class="mb-3">
                            <div class="mb-3">
                                <label for="newPasswordReset" class="form-label">New Password</label>
                                <input type="password" class="form-control" id="newPasswordReset" placeholder="Enter new password">
                            </div>
                            <div class="mb-3">
                                <label for="confirmNewPasswordReset" class="form-label">Confirm New Password</label>
                                <input type="password" class="form-control" id="confirmNewPasswordReset" placeholder="Confirm new password">
                            </div>
                        </div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" id="sendResetBtn">Send OTP</button>
                    <button type="button" class="btn btn-primary" id="verifyOtpBtn" style="display:none;">Verify OTP</button>
                    <button type="button" class="btn btn-primary" id="resetPasswordBtn" style="display:none;">Reset Password</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="./assets/jquery.validate.min.js"></script>
    <script src="./assets/additional-methods.min.js"></script>
    <script src="./assets/users.js"></script>

</body>
</html>