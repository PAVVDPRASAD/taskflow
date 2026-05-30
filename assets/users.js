let profileOriginalValues = {
    fullName: '',
    email: '',
    phoneNumber: ''
};

function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

function isValidPhoneNumber(phone) {
    const digits = phone.replace(/[^0-9]/g, '');
    return digits.length >= 10 && digits.length <= 15;
}

function isStrongPassword(password) {
    const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$/;
    return strongPasswordRegex.test(password);
}

function registerUser() {
    const userName = $('#username').val().trim();
    const fullName = $('#fullName').val().trim();
    const phoneNumber = $('#phoneNumber').val().trim();
    const email = $('#email').val().trim();
    const password = $('#password').val().trim();
    const errorMsg = $('#registerError');

    errorMsg.addClass('d-none').text('');
    
    const submitBtn = $('#registerForm').find("button[type='submit']");
    submitBtn.prop('disabled', true);

    $.ajax({
        url: '/taskflow/components/UserService.cfc',
        type: 'POST',
        dataType: 'json',
        data: {
            method: 'registerUser',
            returnformat: 'json',
            UserName: userName,
            FullName: fullName,
            PhoneNumber: phoneNumber,
            Email: email,
            Password: password,
            csrfToken: $('#csrfToken').val()
        },
        success: function (response) {
            if (response.status === 'success') {
                window.location.href = '/taskflow/dashboard.cfm';
            } else {
                errorMsg.removeClass('d-none').text(response.message);
            }
            submitBtn.prop('disabled', false);
        },
        error: function (xhr, status, error) {
            console.error('Registration error:', status, error, xhr.responseText);
            let errMsg = 'Something went wrong. Please try again.';
            
            errorMsg.removeClass('d-none').text(errMsg);
            submitBtn.prop('disabled', false);
        }
    });
}

function loginUser() {
    const loginID = $('#loginID').val().trim();
    const password = $('#loginPassword').val().trim();
    const csrfToken = $('#csrfToken').val();
    const errorMsg = $('#loginError');

    errorMsg.addClass('d-none').text('');

    const submitBtn = $('#loginForm').find("button[type='submit']");
    submitBtn.prop('disabled', true);

    $.ajax({
        url: '/taskflow/components/UserService.cfc?method=loginUser',
        type: 'POST',
        data: { 
            loginID: loginID, 
            Password: password,
            csrfToken: csrfToken
        },
        dataType: 'json',
        success: function (response) {
            if (response.status === 'success') {
                window.location.href = '/taskflow/dashboard.cfm';
            } else {
                errorMsg.removeClass('d-none').text(response.message);
            }
            submitBtn.prop('disabled', false);
        },
        error: function () {
            errorMsg.removeClass('d-none').text('Something went wrong. Please try again.');
            submitBtn.prop('disabled', false);
        }
    });
}

if (typeof escapeHtml === 'undefined') {
    function escapeHtml(text) {
        if (text === null || text === undefined) return '';
        return String(text)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }
}

function showFormMessage(selector, message, isError = true) {
    const element = $(selector);
    if (!element.length) {
        return;
    }
    if (!message) {
        element.addClass('d-none').text('');
        return;
    }
    element.removeClass('d-none');
    element.toggleClass('alert-danger', isError);
    element.toggleClass('alert-success', !isError);
    element.text(message);
}

function toggleProfilePasswordFields(show) {
    $('#passwordFields, #confirmPasswordFields, #currentPasswordFields').toggleClass('d-none', !show);
    if (!show) {
        $('#newPassword, #confirmNewPassword, #currentPassword').val('');
    }
}

function setProfileEditState(enabled) {
    if (enabled) {
        profileOriginalValues = {
            fullName: $('#fullName').val(),
            email: $('#email').val(),
            phoneNumber: $('#phoneNumber').val()
        };
    }

    $('#fullName, #email, #phoneNumber').prop('disabled', !enabled);
    $('#editBtn').toggle(!enabled);
    $('#saveBtn, #cancelBtn, #changePasswordBtn').toggle(enabled);
    if (!enabled) {
        toggleProfilePasswordFields(false);
        showFormMessage('#profileFormError', '');
    }
}

function saveUserProfile() {
    const userId = $('#profileUserId').val();
    const fullName = $('#fullName').val().trim();
    const email = $('#email').val().trim();
    const phoneNumber = $('#phoneNumber').val().trim();
    const currentPassword = $('#currentPassword').val().trim();
    const newPassword = $('#newPassword').val().trim();
    const confirmNewPassword = $('#confirmNewPassword').val().trim();

    showFormMessage('#profileFormError', '');

    if (!fullName || !email || !phoneNumber) {
        showFormMessage('#profileFormError', 'Please complete all required fields.');
        return;
    }
    if (!isValidEmail(email)) {
        showFormMessage('#profileFormError', 'Please enter a valid email address.');
        return;
    }
    if (!isValidPhoneNumber(phoneNumber)) {
        showFormMessage('#profileFormError', 'Please enter a valid phone number with 10 to 15 digits.');
        return;
    }
    if ($('#passwordFields').is(':visible')) {
        if (!newPassword || !confirmNewPassword) {
            showFormMessage('#profileFormError', 'Please Enter and confirm your new password.');
            return;
        }
        if (!currentPassword) {
            showFormMessage('#profileFormError', 'Please enter your current password.');
            return;
        }
        if (newPassword !== confirmNewPassword) {
            showFormMessage('#profileFormError', 'New passwords do not match.');
            return;
        }
        if (currentPassword === newPassword){
            showFormMessage('#profileFormError', 'New password cannot be the same as the current password.');
            return;
        }
        if (!isStrongPassword(newPassword)) {
            showFormMessage('#profileFormError', 'Password must contain uppercase, lowercase, number and minimum 6 characters.');
            return;
        }
    }

    const saveBtn = $('#saveBtn');
    saveBtn.prop('disabled', true);

    $.ajax({
        url: '/taskflow/components/ProfileService.cfc?method=updateUserProfile',
        type: 'POST',
        dataType: 'json',
        data: {
            UserId: userId,
            FullName: fullName,
            Email: email,
            PhoneNumber: phoneNumber,
            currentPassword: $('#currentPasswordFields').is(':visible') ? currentPassword : '',
            NewPassword: $('#passwordFields').is(':visible') ? newPassword : '',
            csrfToken: $('#csrfToken').val()
        },
        success: function (response) {
            saveBtn.prop('disabled', false);
            if (response.status === 'success') {
                showFormMessage('#profileFormError', 'Profile updated successfully.', false);
                $('#fullName').val(response.user.fullName);
                $('#email').val(response.user.email);
                $('#phoneNumber').val(response.user.phoneNumber);
                profileOriginalValues = {
                    fullName: response.user.fullName,
                    email: response.user.email,
                    phoneNumber: response.user.phoneNumber
                };
                setProfileEditState(false);
            } else {
                showFormMessage('#profileFormError', response.message || 'Could not update profile.');
            }
        },
        error: function () {
            saveBtn.prop('disabled', false);
            showFormMessage('#profileFormError', 'Server error. Please try again later.');
        }
    });
}

function submitForgotPassword() {
    const email = $('#forgotEmail').val().trim();
    showFormMessage('#forgotPasswordError', '');
    showFormMessage('#forgotPasswordSuccess', '');

    if (!email) {
        showFormMessage('#forgotPasswordError', 'Please enter your email address.');
        return;
    }
    if (!isValidEmail(email)) {
        showFormMessage('#forgotPasswordError', 'Please enter a valid email address.');
        return;
    }

    const button = $('#sendResetBtn');
    button.prop('disabled', true);

    $.ajax({
        url: '/taskflow/components/UserService.cfc?method=sendOTPRequest',
        type: 'POST',
        dataType: 'json',
        data: {
            Email: email,
            csrfToken: $('#csrfToken').val()
        },
        success: function (response) {
            button.prop('disabled', false);
            if (response.status === 'success') {
                showFormMessage('#forgotPasswordSuccess', response.message, false);
                $('#forgotEmailSection').hide();
                $('#sendResetBtn').hide();
                $('#otpSection').show();
                $('#verifyOtpBtn').show();
            } else {
                showFormMessage('#forgotPasswordError', response.message);
            }
        },
        error: function () {
            button.prop('disabled', false);
            showFormMessage('#forgotPasswordError', 'Server error. Please try again later.');
        }
    });
}

function verifyOTP() {
    const email = $('#forgotEmail').val().trim();
    const otp = $('#otpInput').val().trim();
    showFormMessage('#forgotPasswordError', '');
    showFormMessage('#forgotPasswordSuccess', '');

    if (!otp) {
        showFormMessage('#forgotPasswordError', 'Please enter the OTP.');
        return;
    }

    const button = $('#verifyOtpBtn');
    button.prop('disabled', true);

    $.ajax({
        url: '/taskflow/components/UserService.cfc?method=verifyOTP',
        type: 'POST',
        dataType: 'json',
        data: {
            Email: email,
            OTP: otp,
            csrfToken: $('#csrfToken').val()
        },
        success: function (response) {
            button.prop('disabled', false);
            if (response.status === 'success') {
                showFormMessage('#forgotPasswordSuccess', response.message, false);
                $('#otpSection').hide();
                $('#verifyOtpBtn').hide();
                $('#passwordSection').show();
                $('#resetPasswordBtn').show();
            } else {
                showFormMessage('#forgotPasswordError', response.message);
            }
        },
        error: function () {
            button.prop('disabled', false);
            showFormMessage('#forgotPasswordError', 'Server error. Please try again later.');
        }
    });
}

function resetPassword() {
    const email = $('#forgotEmail').val().trim();
    const newPassword = $('#newPasswordReset').val().trim();
    const confirmNewPassword = $('#confirmNewPasswordReset').val().trim();
    showFormMessage('#forgotPasswordError', '');
    showFormMessage('#forgotPasswordSuccess', '');

    if (!newPassword || !confirmNewPassword) {
        showFormMessage('#forgotPasswordError', 'Please enter and confirm your new password.');
        return;
    }
    if (newPassword !== confirmNewPassword) {
        showFormMessage('#forgotPasswordError', 'New passwords do not match.');
        return;
    }
    if (!isStrongPassword(newPassword)) {
        showFormMessage('#forgotPasswordError', 'Password must contain uppercase, lowercase, number and minimum 6 characters.');
        return;
    }

    const button = $('#resetPasswordBtn');
    button.prop('disabled', true);

    $.ajax({
        url: '/taskflow/components/UserService.cfc?method=resetPassword',
        type: 'POST',
        dataType: 'json',
        data: {
            Email: email,
            NewPassword: newPassword,
            csrfToken: $('#csrfToken').val()
        },
        success: function (response) {
            button.prop('disabled', false);
            if (response.status === 'success') {
                showFormMessage('#forgotPasswordSuccess', response.message, false);
                $('#forgotPasswordModal').modal('hide');
                $('#forgotPasswordForm')[0].reset();
                // Reset modal state for next time
                $('#forgotEmailSection').show();
                $('#sendResetBtn').show();
                $('#otpSection').hide();
                $('#verifyOtpBtn').hide();
                $('#passwordSection').hide();
                $('#resetPasswordBtn').hide();
            } else {
                showFormMessage('#forgotPasswordError', response.message);
            }
        },
        error: function () {
            button.prop('disabled', false);
            showFormMessage('#forgotPasswordError', 'Server error. Please try again later.');
        }
    });
}

$(document).ready(function () {

    const fileInput = $('#profilePhotoInput');
    const changePhotoBtn = $('#changePhotoBtn');

    fileInput.on('change', function() {
        const file = this.files[0];
        if (!file) {
            showFormMessage('#profileFormError', 'Please select an image file to upload.');
            return;
        }

        const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
        if (!allowedTypes.includes(file.type)) {
            showFormMessage('#profileFormError', 'Unsupported image type. Only JPEG and PNG are allowed.');
            fileInput.val('');
            return;
        }

        
        if (file.size > (5 * 1024 * 1024)) {
            showFormMessage('#profileFormError', "File size exceeds 5 MB limit.");
            fileInput.val('');
            return;
        }

        const reader = new FileReader();
        reader.onload = function (e) {
            $('#profilePhotoPreview').attr('src', e.target.result);
        };
        reader.readAsDataURL(file);

        const userId = $('#profileUserId').val();
        const formData = new FormData();
        formData.append('ProfilePhoto', file);
        formData.append('UserId', userId);
        formData.append('csrfToken', $('#csrfToken').val());
        
        showFormMessage('#profileFormError', ''); 
        changePhotoBtn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Uploading...');

        $.ajax({
            url: '/taskflow/components/ProfileService.cfc?method=updateProfilePhoto',
            type:'POST',
            data: formData,
            processData: false,
            contentType: false,
            dataType: 'json',

            success: function(response) {
                changePhotoBtn.prop('disabled', false).html('<i class="fa-solid fa-camera shadow fw-bold"></i>');
                if (response.status === 'success') {
                    showFormMessage('#profileFormError', response.message || 'Profile photo updated successfully.', false);
                    
                } else {
                    showFormMessage('#profileFormError', response.message || 'Could not update profile photo.');
                }
            },
            error: function() {
                changePhotoBtn.prop('disabled', false).html('<i class="fa-solid fa-camera shadow fw-bold"></i>');
                showFormMessage('#profileFormError', 'Server error. Please try again later.');
            }
        });
    });

    if ($('#registerForm').length) {
        $.validator.addMethod('strongPassword', function (value, element) {
            return this.optional(element) || /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$/.test(value);
        }, 'Password must contain uppercase, lowercase, number and minimum 6 characters.');

        $('#registerForm').validate({
            rules: {
                UserName: {
                    required: true,
                    minlength: 4,
                    maxlength: 50
                },
                FullName: {
                    required: true,
                    minlength: 3,
                    maxlength: 50
                },
                PhoneNumber: {
                    required: true,
                    minlength: 10,
                    maxlength: 20
                },
                Email: {
                    required: true,
                    email: true
                },
                Password: {
                    required: true,
                    strongPassword: true
                },
                ConfirmPassword: {
                    required: true,
                    equalTo: '#password'
                },
                TermsAccepted: {
                    required: true
                }
            },
            messages: {
                UserName: {
                    required: 'Username is required.',
                    minlength: 'Username must be at least 4 characters long.',
                    maxlength: 'Username cannot exceed 50 characters.'
                },
                FullName: {
                    required: 'Full name is required.',
                    minlength: 'Full name must be at least 3 characters long.',
                    maxlength: 'Full name cannot exceed 50 characters.'
                },
                PhoneNumber: {
                    required: 'Phone number is required.',
                    minlength: 'Phone number must be at least 10 digits.',
                    maxlength: 'Phone number cannot exceed 20 characters.'
                },
                Email: {
                    required: 'Email address is required.',
                    email: 'Please enter a valid email address.'
                },
                Password: {
                    required: 'Password is required.'
                },
                ConfirmPassword: {
                    required: 'Please confirm your password.',
                    equalTo: 'Passwords do not match.'
                },
                TermsAccepted: {
                    required: 'You must accept the terms and conditions.'
                }
            },
            errorClass: 'is-invalid',
            validClass: 'is-valid',
            errorElement: 'div',
            errorPlacement: function (error, element) {
                if (element.attr('type') === 'checkbox') {
                    error.addClass('d-block mt-2');
                    element.closest('.form-check').after(error);
                } else {
                    error.addClass('d-block invalid-feedback');
                    element.after(error);
                }
            },
            highlight: function (element, errorClass, validClass) {
                $(element).addClass('is-invalid').removeClass('is-valid');
            },
            unhighlight: function (element, errorClass, validClass) {
                $(element).addClass('is-valid').removeClass('is-invalid');
            },
            submitHandler: function (form) {
                registerUser();
            }
        });
    }

    if ($('#loginForm').length) {
        $('#loginForm').validate({
            rules: {
                loginID: {
                    required: true,
                    minlength: 3,
                    maxlength: 50
                },
                Password: {
                    required: true,
                    minlength: 6
                }
            },
            messages: {
                loginID: {
                    required: 'Username or email is required.',
                    minlength: 'Username or email must be at least 3 characters long.',
                    maxlength: 'Username or email cannot exceed 50 characters.'
                },
                Password: {
                    required: 'Password is required.',
                    minlength: 'Password must be at least 6 characters long.'
                }
            },
            errorClass: 'is-invalid',
            validClass: 'is-valid',
            errorElement: 'div',
            errorPlacement: function (error, element) {
                error.addClass('d-block invalid-feedback');
                element.after(error);
            },
            highlight: function (element, errorClass, validClass) {
                $(element).addClass('is-invalid').removeClass('is-valid');
            },
            unhighlight: function (element, errorClass, validClass) {
                $(element).addClass('is-valid').removeClass('is-invalid');
            },
            submitHandler: function (form) {
                loginUser();
            }
        });
    }

    if ($('#forgotPasswordForm').length) {
        $.validator.addMethod('strongPasswordReset', function (value, element) {
            return this.optional(element) || /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$/.test(value);
        }, 'Password must contain uppercase, lowercase, number and minimum 6 characters.');

        $('#forgotPasswordForm').validate({
            rules: {
                forgotEmail: {
                    required: true,
                    email: true
                },
                otpInput: {
                    required: true,
                    digits: true,
                    minlength: 6,
                    maxlength: 6
                },
                newPasswordReset: {
                    required: true,
                    strongPasswordReset: true
                },
                confirmNewPasswordReset: {
                    required: true,
                    equalTo: '#newPasswordReset'
                }
            },
            messages: {
                forgotEmail: {
                    required: 'Email is required.',
                    email: 'Please enter a valid email address.'
                },
                otpInput: {
                    required: 'OTP is required.',
                    digits: 'OTP must contain only digits.',
                    minlength: 'OTP must be 6 digits.',
                    maxlength: 'OTP must be 6 digits.'
                },
                newPasswordReset: {
                    required: 'New password is required.'
                },
                confirmNewPasswordReset: {
                    required: 'Please confirm your password.',
                    equalTo: 'Passwords do not match.'
                }
            },
            errorClass: 'is-invalid',
            validClass: 'is-valid',
            errorElement: 'div',
            errorPlacement: function (error, element) {
                error.addClass('d-block invalid-feedback');
                element.after(error);
            },
            highlight: function (element, errorClass, validClass) {
                $(element).addClass('is-invalid').removeClass('is-valid');
            },
            unhighlight: function (element, errorClass, validClass) {
                $(element).addClass('is-valid').removeClass('is-invalid');
            }
        });
    }

    if ($('#loginForm').length) {

        $('#forgotPasswordLink').click(function (e) {
            e.preventDefault();
            $('#forgotPasswordModal').modal('show');
        });

        $('#sendResetBtn').click(function () {
            submitForgotPassword();
        });

        $('#verifyOtpBtn').click(function () {
            verifyOTP();
        });

        $('#otpSection').submit(function (e) { 
            e.preventDefault();
            verifyOTP();
        });

        $('#resetPasswordBtn').click(function () {
            resetPassword();
        });

        $('#forgotPasswordForm').submit(function (e) {
            e.preventDefault();
            submitForgotPassword();
        });

    } 

    if ($('#profileForm').length) {
        setProfileEditState(false);

        $('#editBtn').click(function () {
            setProfileEditState(true);
        });

        $('#cancelBtn').click(function () {
            setProfileEditState(false);
            $('#fullName').val(profileOriginalValues.fullName);
            $('#email').val(profileOriginalValues.email);
            $('#phoneNumber').val(profileOriginalValues.phoneNumber);
        });

        $('#changePasswordBtn').click(function () {
            toggleProfilePasswordFields(true);
        });

        $('#saveBtn').click(function (e) {
            e.preventDefault();
            saveUserProfile();
        });

        $('#changePhotoBtn').click(function (e) {
            e.preventDefault();
            $('#profilePhotoInput').click();
        })
    }

    if ($('#logoutBtn').length) {
        $('#logoutBtn').click(function (e) {
            e.preventDefault();
            $.ajax({
                url: '/taskflow/components/UserService.cfc?method=logoutUser',
                type: 'POST',
                dataType: 'json',
                data: {
                    csrfToken: $('#csrfToken').val()
                },
                success: function (response) {
                    if (response.status === 'success') {
                        window.location.href = '/taskflow/login.cfm';
                    }
                }
            });
        });
    }

});
