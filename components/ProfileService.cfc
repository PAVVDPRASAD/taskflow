<cfcomponent>
    <cffunction name="validateProfileData" access="private" returntype="string" output="false">
        <cfargument name="FullName" type="string" required="true">
        <cfargument name="Email" type="string" required="true">
        <cfargument name="PhoneNumber" type="string" required="true">

        <cfif len(trim(arguments.FullName)) LTE 2 OR len(trim(arguments.FullName)) GT 100>
            <cfreturn "Full name is required and must be 3-100 characters." />
        </cfif>

        <cfif NOT isValid("email", trim(arguments.Email))>
            <cfreturn "Invalid email format." />
        </cfif>

        <cfset cleanedPhone = reReplace(trim(arguments.PhoneNumber), "[^0-9]", "", "all")>
        <cfif len(cleanedPhone) LT 10 OR len(cleanedPhone) GT 15>
            <cfreturn "Phone number must be between 10 and 15 digits." />
        </cfif>

        <cfreturn "">
    </cffunction>

    <cffunction name="updateUserProfile" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="FullName" type="string" required="true">
        <cfargument name="Email" type="string" required="true">
        <cfargument name="PhoneNumber" type="string" required="true">
        <cfargument name="CurrentPassword" type="string" required="false" default="">
        <cfargument name="NewPassword" type="string" required="false" default="">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset userId = session.user.id>

        <cfset arguments.FullName = trim(arguments.FullName)>
        <cfset arguments.Email = trim(arguments.Email)>
        <cfset arguments.PhoneNumber = trim(arguments.PhoneNumber)>

        <cfset validationError = validateProfileData(
            FullName = arguments.FullName,
            Email = arguments.Email,
            PhoneNumber = arguments.PhoneNumber
        )>

        <cfif validationError NEQ "">
            <cfreturn { "status":"error", "message":validationError }>
        </cfif>

        <cfquery name="checkEmail" datasource="#application.DBS#">
            SELECT user_id FROM dbo.userAuth
            WHERE email = <cfqueryparam value="#arguments.Email#" cfsqltype="cf_sql_nvarchar">
            AND user_id != <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif checkEmail.recordCount GT 0>
            <cfreturn { "status":"error", "message":"Email is already in use by another account." }>
        </cfif>

        <cfif len(trim(arguments.CurrentPassword)) GT 0>
            <cfquery name="checkPass" datasource="#application.DBS#">
                SELECT password_hash FROM dbo.userAuth
                WHERE user_id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif checkPass.recordCount EQ 0>
                <cfreturn { "status":"error", "message":"User not found" }>
            </cfif>
            <cfif NOT verifyBCryptHash(trim(arguments.CurrentPassword), checkPass.password_hash[1])>
                <cfreturn { "status":"error", "message":"Current password is incorrect" }>
            </cfif>
        </cfif>

        <cftry>
            <cfif len(trim(arguments.NewPassword)) GT 0>
                <cfif REFind("^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$", arguments.NewPassword) EQ 0>
                    <cfreturn { "status":"error", "message":"New password must contain uppercase, lowercase, number and minimum 6 characters." }>
                </cfif>
                <cfset passwordHash = generateBCryptHash(arguments.NewPassword)>
            <cfelse>
                <cfset passwordHash = "">
            </cfif>

            <cfquery datasource="#application.DBS#">
                UPDATE dbo.userAuth
                SET full_name = <cfqueryparam value="#arguments.FullName#" cfsqltype="cf_sql_nvarchar">,
                    phone = <cfqueryparam value="#arguments.PhoneNumber#" cfsqltype="cf_sql_nvarchar">,
                    email = <cfqueryparam value="#arguments.Email#" cfsqltype="cf_sql_nvarchar">
                    <cfif len(passwordHash) GT 0>
                      ,  password_hash = <cfqueryparam value="#passwordHash#" cfsqltype="cf_sql_nvarchar">
                    </cfif>
                WHERE user_id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfquery name="updatedUser" datasource="#application.DBS#">
                SELECT user_id, username, email, full_name, phone, profile_pic FROM dbo.userAuth
                WHERE user_id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfif updatedUser.recordCount EQ 1>
                <cfset session.user = {
                    "id": updatedUser.user_id[1],
                    "username": updatedUser.username[1],
                    "email": updatedUser.email[1],
                    "fullName": updatedUser.full_name[1],
                    "phoneNumber": updatedUser.phone[1],
                    "profilePhoto": updatedUser.profile_pic[1]
                }>
                <cfreturn { "status":"success", "message":"Profile updated successfully", "user": session.user }>
            <cfelse>
                <cfreturn { "status":"error", "message":"Unable to load updated profile information." }>
            </cfif>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Server Error: Profile update failed" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="updateProfilePhoto" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif NOT structKeyExists(session, "csrfToken") OR arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status" = "error", "message" = "Invalid CSRF token" }>
        </cfif>

        <cfset var userId = session.user.id>

        <cfset var tempUploadPath = "C:\ColdFusion2023\cfusion\temp_img">

        <cfset var finalUploadPath = expandPath("/taskflow/assets/images/")>

        <cfset var allowedTypes = "jpg,jpeg,png">
        <cfset var allowedMime = "jpeg,png">
        <cfset var maxFileSize = 5 * 1024 * 1024>

        <cfset var uploadResult = "">
        <cfset var oldPhotoPath = "">
        <cfset var newFileName = "">
        <cfset var fileExtension = "">

        <cftry>
            <cfif NOT structKeyExists(form, "ProfilePhoto")>
                <cfreturn { "status" = "error", "message" = "Please select an image" }>
            </cfif>

            <cffile
                action="upload"
                filefield="ProfilePhoto"
                destination="#tempUploadPath#"
                nameconflict="makeunique"
                result="uploadResult">

            <cfset fileExtension = lcase(uploadResult.serverFileExt)>

            <cfif NOT listFindNoCase(allowedTypes, fileExtension)>
                <cffile action="delete" file="#uploadResult.serverDirectory#/#uploadResult.serverFile#">
                <cfreturn { "status" = "error", "message" = "Only JPG, JPEG and PNG files allowed" }>
            </cfif>

            <cfif uploadResult.contentType NEQ "image" OR NOT listFindNoCase(allowedMime, uploadResult.contentSubType)>

                <cffile
                    action="delete"
                    file="#uploadResult.serverDirectory#/#uploadResult.serverFile#">

                <cfreturn { "status" = "error", "message" = "Invalid image file" }>
            </cfif>

            <cfif uploadResult.fileSize GT maxFileSize>
                <cffile
                    action="delete"
                    file="#uploadResult.serverDirectory#/#uploadResult.serverFile#">

                <cfreturn { "status" = "error", "message" = "File size exceeds 5MB limit" }>
            </cfif>

            <cfset newFileName = createUUID() & "." & fileExtension>

            <cffile
                action="move"
                source="#uploadResult.serverDirectory#/#uploadResult.serverFile#"
                destination="#finalUploadPath##newFileName#">

            <cfquery name="getOldPhoto" datasource="#application.DBS#">
                SELECT profile_pic
                FROM dbo.userAuth
                WHERE user_id =
                <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfif getOldPhoto.recordCount GT 0 AND len(trim(getOldPhoto.profile_pic[1]))>
                <cfset oldPhotoPath = expandPath( "/taskflow/assets/images/#getOldPhoto.profile_pic[1]#" )>

                <cfif fileExists(oldPhotoPath)>
                    <cffile
                        action="delete"
                        file="#oldPhotoPath#">
                </cfif>
            </cfif>

            <cfquery datasource="#application.DBS#">
                UPDATE dbo.userAuth
                SET profile_pic = <cfqueryparam value="#newFileName#" cfsqltype="cf_sql_nvarchar">
                WHERE user_id = <cfqueryparam  value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset session.user.profilePhoto = newFileName>

            <cfreturn { "status" = "success", "message" = "Profile photo updated successfully", "photoUrl" = "/taskflow/assets/images/#newFileName#" }>

        <cfcatch type="any">
            <cfif isStruct(uploadResult) AND structKeyExists(uploadResult, "serverFile")>
                <cfset tempFile =
                    uploadResult.serverDirectory
                    & "/"
                    & uploadResult.serverFile>

                <cfif fileExists(tempFile)>
                    <cffile
                        action="delete"
                        file="#tempFile#">
                </cfif>
            </cfif>

            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status" = "error", "message" = "Server Error: Profile photo update failed" }>

        </cfcatch>
        </cftry>

    </cffunction>

    <cffunction name="changePassword" access="remote" returntype="struct" returnformat="json" output="false">
        
    </cffunction>
</cfcomponent>
