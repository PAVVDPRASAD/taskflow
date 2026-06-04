<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">
    <title>Register - TaskFlow</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"
          rel="stylesheet">
</head>

<body class="bg-dark">
    <div class="container d-flex justify-content-center align-items-center min-vh-100">
        <div class="col-12 col-md-8 col-lg-5">
            <div class="card shadow p-4">
                <h3 class="text-center mb-4">
                    User Registration
                </h3>

                <form id="registerForm">
                    <input type="hidden" id="csrfToken" value="<cfoutput>#session.csrfToken#</cfoutput>">
                    <div class="form-floating mb-3">
                        <input type="text"
                               class="form-control"
                               name="UserName"
                               id="username"
                               placeholder="Username"
                               autocomplete="username"
                               minlength="4">
                        <label for="username">Username</label>
                    </div>

                    <div class="form-floating mb-3">
                        <input type="text"
                               class="form-control"
                               name="FullName"
                               id="fullName"
                               placeholder="Full Name"
                               autocomplete="name"
                               minlength="3">
                        <label for="fullName">Full Name</label>
                    </div>

                    <div class="form-floating mb-3">
                        <input type="tel"
                               class="form-control"
                               name="PhoneNumber"
                               id="phoneNumber"
                               placeholder="Phone Number"
                               autocomplete="tel"
                               pattern="[0-9+\(\)\-\s]{10,20}">
                        <label for="phoneNumber">Phone Number</label>
                    </div>

                    <div class="form-floating mb-3 position-relative">
                        <input type="email"
                               class="form-control"
                               name="Email"
                               id="email"
                               placeholder="Email"
                               autocomplete="email">
                        <label for="email">Email Address</label>
                        <button type="button" 
                                class="position-absolute top-0 end-0 mt-3 me-2 btn btn-sm btn-primary" 
                                id="verifyEmail">
                                Verify
                        </button>
                    </div>
                 
                    <div class="form-floating mb-3">
                        <input type="password"
                               class="form-control"
                               name="Password"
                               id="password"
                               placeholder="Password"
                               autocomplete="new-password">
                        <label for="password">Password</label>
                    </div>

                    <div class="form-floating mb-3">
                        <input type="password"
                               class="form-control"
                               name="ConfirmPassword"
                               id="confirmPassword"
                               placeholder="Confirm Password">
                        <label for="confirmPassword">Confirm Password</label>
                    </div>
                    <div class="mb-3 form-check">
                        <input type="checkbox"
                               class="form-check-input"
                               name="TermsAccepted"
                               id="termsAccepted">
                        <label for="termsAccepted" class="form-check-label">
                            I agree to the <a href="./terms.cfm" target="_blank" class="text-decoration-none">Terms and Conditions</a>
                        </label>
                    </div>

                    <div id="registerError"
                         class="alert alert-danger d-none">
                    </div>

                    <div class="d-grid">
                        <button type="submit" class="btn btn-primary btn-lg">Register</button>
                    </div>

                    <p class="text-center mt-3 mb-0">Already have an account?
                        <a href="login.cfm" class="text-decoration-none">Login here</a>
                    </p>
                </form>
            </div>
        </div>
    </div>

    <div class="modal fade" id="emailVerifyModal" tabindex="-1" aria-labelledby="emailVerifyModalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="emailVerifyModalLabel">Verify Email</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form id="emailVerifyForm">
                        <div id="emailVerifyError" class="alert alert-danger d-none"></div>
                        <div id="emailVerifySuccess" class="alert alert-success d-none"></div>
                        <div class="mb-3" id="emailSection">
                            <label for="email" class="form-label">Email address</label>
                            <input type="email" class="form-control" id="email" placeholder="Enter your registered email">
                        </div>
                        <div id="otpSection" style="display:none;" class="mb-3">
                            <div class="otp-container">
                                <h2>Enter 6-digit OTP</h2>
                                <div class="otp-inputs">
                                <input type="text" maxlength="1">
                                <input type="text" maxlength="1">
                                <input type="text" maxlength="1">
                                <input type="text" maxlength="1">
                                <input type="text" maxlength="1">
                                <input type="text" maxlength="1">
                                </div>
                                <button class="btn btn-primary" onclick="verifyOTP()">Verify</button>
                            </div>
                        </div>
                        <div id="passwordSection" style="display:none;" class="mb-3">
                            
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