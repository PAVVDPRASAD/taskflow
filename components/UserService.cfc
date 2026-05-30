<cfcomponent displayname="User Service" output="false">

    <cffunction name="validateUserData" access="private" returntype="string" output="false">
        <cfargument  name="UserName" type="string" required="true">
        <cfargument  name="Email" type="string" required="true">
        <cfargument  name="Password" type="string" required="true">
        <cfargument  name="FullName" type="string" required="true">
        <cfargument  name="PhoneNumber" type="string" required="true">

        <cfif len(trim(arguments.UserName)) LTE 3 OR len(trim(arguments.UserName)) GT 100>
            <cfreturn "Username is required and must be 4-100 characters." />
        </cfif>

        <cfif len(trim(arguments.FullName)) LTE 2 OR len(trim(arguments.FullName)) GT 100>
            <cfreturn "Full name is required and must be 3-100 characters." />
        </cfif>

        <cfset cleanedPhone = reReplace(trim(arguments.PhoneNumber), "[^0-9]", "", "all")>
        <cfif len(cleanedPhone) LT 10 OR len(cleanedPhone) GT 15>
            <cfreturn "Phone number must be between 10 and 15 digits." />
        </cfif>

        <cfif NOT isValid("email", trim(arguments.Email))>
            <cfreturn "Invalid email format." />
        </cfif>

        <cfif REFind("^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$", arguments.Password) EQ 0>
            <cfreturn "Password must contain uppercase, lowercase, number and minimum 6 characters." />
        </cfif>

        <cfreturn "">
    </cffunction>

    <cffunction name="registerUser" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument  name="UserName" type="string" required="true">
        <cfargument  name="Email" type="string" required="true">
        <cfargument  name="Password" type="string" required="true">
        <cfargument  name="FullName" type="string" required="true">
        <cfargument  name="PhoneNumber" type="string" required="true">
        <cfargument  name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset hashedPassword = generateBCryptHash(trim(arguments.Password))>
        
        <cfset arguments.Email = trim(arguments.Email)>
        <cfset arguments.FullName = trim(arguments.FullName)>
        <cfset arguments.PhoneNumber = trim(arguments.PhoneNumber)>

        <cfset validationError = validateUserData(
            UserName = arguments.UserName,
            Email = arguments.Email,
            Password = arguments.Password,
            FullName = arguments.FullName,
            PhoneNumber = arguments.PhoneNumber
        )>

        <cfif validationError NEQ "">
            <cfreturn { "status":"error", "message":validationError }>
        </cfif>

        <cfquery name="checkUser" datasource="#application.DBS#">
            SELECT user_id FROM dbo.userAuth WHERE
            email = <cfqueryparam value="#arguments.Email#" cfsqltype="cf_sql_nvarchar">
            OR username = <cfqueryparam value="#arguments.UserName#" cfsqltype="cf_sql_nvarchar">
        </cfquery>
        <cfif checkUser.recordCount GT 0 >
            <cfreturn { "status":"error", "message":"User already exists" }>
        </cfif>

        <cftry>
            <cfquery datasource="#application.DBS#">
                INSERT INTO dbo.userAuth (username, email, password_hash, full_name, phone) 
                VALUES (
                    <cfqueryparam value="#arguments.UserName#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#arguments.Email#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#hashedPassword#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#arguments.FullName#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#arguments.PhoneNumber#" cfsqltype="cf_sql_nvarchar">
                )
            </cfquery>

            <cfquery name="newLogin" datasource="#application.DBS#">
                SELECT user_id, username, email, full_name, phone, profile_pic FROM dbo.userAuth
                WHERE 
                    email = <cfqueryparam value="#arguments.Email#" cfsqltype="cf_sql_nvarchar"> 
            </cfquery>

            <cfif newLogin.recordCount EQ 1>
                <cfset session.isLoggedIn = true>
                <cfset session.user = {
                    "id": newLogin.user_id[1],
                    "username": newLogin.username[1],
                    "email": newLogin.email[1],
                    "fullName": newLogin.full_name[1],
                    "phoneNumber": newLogin.phone[1],
                    "profilePhoto": newLogin.profile_pic[1]
                }>
                <cfset session.lastActivity = now()>
                <cfset session.csrfToken = createUUID()>
            </cfif>

            <cfreturn { "status":"success", "message":"User registered successfully" }>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Server Error: Registration failed" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction  name="loginUser" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="loginID" type="string" required="true">
        <cfargument  name="Password" type="string" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cftry>
            <cfquery name="uLogin" datasource="#application.DBS#">
                SELECT user_id, username, email, password_hash, full_name, phone, profile_pic FROM dbo.userAuth
                WHERE 
                    (email = <cfqueryparam value="#trim(arguments.loginID)#" cfsqltype="cf_sql_nvarchar"> 
                    OR username=<cfqueryparam value="#trim(arguments.loginID)#" cfsqltype="cf_sql_nvarchar">)
            </cfquery>

            <cfif uLogin.recordCount EQ 1>
                <cfif verifyBCryptHash(trim(arguments.Password), uLogin.password_hash[1])>
                    <cfset session.isLoggedIn = true>
                    <cfset session.user = {
                        "id": uLogin.user_id[1],
                        "username": uLogin.username[1],
                        "email": uLogin.email[1],
                        "fullName": uLogin.full_name[1],
                        "phoneNumber": uLogin.phone[1],
                        "profilePhoto": uLogin.profile_pic[1]
                    }>
                    <cfset session.lastActivity = now()>
                    <cfset session.csrfToken = createUUID()>
                    <cfreturn { "status":"success", "message":"Login successful" }>
                <cfelse>
                    <cfreturn { "status":"error", "message":"Invalid credentials" }>
                </cfif>
            <cfelse>
                <cfreturn { "status":"error", "message":"Invalid credentials" }>
            </cfif>
            
            <cfcatch type="any">
                <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
                <cfreturn { "status":"error", "message":"Server Error: Login failed" }>
            </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="logoutUser" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset sessionInvalidate()>
         <cfreturn { "status":"success", "message":"Logout successful" }>
    </cffunction>

    <cffunction name="isLoggedIn" access="remote" returntype="struct" returnformat="json" output="false">
        <cfif structKeyExists(session, "isLoggedIn") AND session.isLoggedIn>
            <cfreturn { "status":"loggedIn" }>
        <cfelse>
            <cfreturn { "status":"notLoggedIn" }>
        </cfif>
    </cffunction>

    <cffunction name="sendOTPRequest" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="Email" type="string" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset email = trim(arguments.Email)>

        <cfif NOT isValid("email", email)>
            <cfreturn { "status":"error", "message":"Invalid email format." }>
        </cfif>

        <cfquery name="getUser" datasource="#application.DBS#">
            SELECT user_id FROM dbo.userAuth
            WHERE email = <cfqueryparam value="#email#" cfsqltype="cf_sql_nvarchar">
        </cfquery>

        <cfif getUser.recordCount EQ 0>
            <cfreturn { "status":"error", "message":"No account found with that email address." }>
        </cfif>

        <cfset var otp = randRange(100000, 999999)>
        <cfset var otpExpiry = dateAdd("n", 10, now())>

        <cftry>
            <cfquery datasource="#application.DBS#">
                UPDATE dbo.userAuth 
                SET reset_otp = <cfqueryparam value="#otp#" cfsqltype="cf_sql_integer">,
                    otp_expiry = <cfqueryparam value="#otpExpiry#" cfsqltype="cf_sql_timestamp">,
                    otp_verified = 0
                WHERE email = <cfqueryparam value="#email#" cfsqltype="cf_sql_nvarchar">
            </cfquery>
            
            <cfmail 
                to="#email#" 
                from="#application.mail.username#" 
                subject="Your Password Reset OTP" 
                server="#application.mail.server#" 
                port="#application.mail.port#" 
                username="#application.mail.username#" 
                password="#application.mail.password#" 
                usetls= true 
                type="text">

                Hello,
                You requested a password reset.
                Your OTP is: #otp#
                This OTP will expire in 10 minutes.

            </cfmail>

            <cfreturn { "status":"success", "message":"OTP has been sent to your email address." }>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Server Error: Could not generate OTP" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="verifyOTP" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="Email" type="string" required="true">
        <cfargument name="OTP" type="string" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
        </cfif>

        <cfset email = trim(arguments.Email)>
        <cfset otp = trim(arguments.OTP)>

        <cfif NOT isValid("email", email)>
            <cfreturn { "status":"error", "message":"Invalid email format." }>
        </cfif>

        <cfif len(otp) NEQ 6 OR NOT isNumeric(otp)>
            <cfreturn { "status":"error", "message":"Invalid OTP format." }>
        </cfif>

        <cfquery name="getUserOtp" datasource="#application.DBS#">
            SELECT user_id, reset_otp, otp_expiry, otp_verified
            FROM dbo.userAuth
            WHERE email = <cfqueryparam value="#email#" cfsqltype="cf_sql_nvarchar">
        </cfquery>

        <cfif getUserOtp.recordCount EQ 0>
            <cfreturn { "status":"error", "message":"No account found with that email address." }>
        </cfif>

        <cfset var user = getUserOtp>

        <cfif NOT isDate(user.otp_expiry[1]) OR now() GT user.otp_expiry[1]>
            <cfreturn { "status":"error", "message":"OTP has expired. Please request a new one." }>
        </cfif>

        <cfif user.otp_verified[1] EQ 1>
            <cfreturn { "status":"error", "message":"OTP already used or invalid state." }>
        </cfif>

        <cfif otp EQ user.reset_otp[1]>
            <cftry>
                <cfquery datasource="#application.DBS#">
                    UPDATE dbo.userAuth
                    SET otp_verified = 1
                    WHERE user_id = <cfqueryparam value="#user.user_id[1]#" cfsqltype="cf_sql_integer">
                </cfquery>
                <cfreturn { "status":"success", "message":"OTP verified successfully." }>
            <cfcatch type="any">
                <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
                <cfreturn { "status":"error", "message":"Server Error: OTP verification failed." }>
            </cfcatch>
            </cftry>
        <cfelse>
            <cfreturn { "status":"error", "message":"Invalid OTP." }>
        </cfif>
    </cffunction>

    <cffunction name="resetPassword" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="Email" type="string" required="true">
        <cfargument name="NewPassword" type="string" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
        </cfif>

        <cfset email = trim(arguments.Email)>
        <cfset newPassword = arguments.NewPassword>

        <cfif NOT isValid("email", email)>
            <cfreturn { "status":"error", "message":"Invalid email format." }>
        </cfif>

        <cfif REFind("^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$", newPassword) EQ 0>
            <cfreturn { "status":"error", "message":"Password must contain uppercase, lowercase, number and minimum 6 characters." }>
        </cfif>

        <cfquery name="getUserForReset" datasource="#application.DBS#">
            SELECT user_id, otp_verified, otp_expiry
            FROM dbo.userAuth
            WHERE email = <cfqueryparam value="#email#" cfsqltype="cf_sql_nvarchar">
        </cfquery>

        <cfif getUserForReset.recordCount EQ 0>
            <cfreturn { "status":"error", "message":"No account found with that email address." }>
        </cfif>

        <cfset var user = getUserForReset>

        <cfif user.otp_verified[1] EQ 0 OR NOT isDate(user.otp_expiry[1]) OR now() GT user.otp_expiry[1]>
            <cfreturn { "status":"error", "message":"Password reset not authorized or OTP expired. Please request a new OTP." }>
        </cfif>

        <cftry>
            <cfset hashedPassword = generateBCryptHash(newPassword)>

            <cfquery datasource="#application.DBS#">
                UPDATE dbo.userAuth
                SET password_hash = <cfqueryparam value="#hashedPassword#" cfsqltype="cf_sql_nvarchar">,
                    reset_otp = NULL,
                    otp_expiry = NULL,
                    otp_verified = 0
                WHERE user_id = <cfqueryparam value="#user.user_id[1]#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfreturn { "status":"success", "message":"Password has been reset successfully." }>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Server Error: Password reset failed." }>
        </cfcatch>
        </cftry>
    </cffunction>

</cfcomponent>