<cfcomponent>
    <cfset this.name = "TaskFlowApp2">
    <cfset this.sessionManagement = true>
    <cfset this.sessionTimeout = createTimespan(0,0,30,0)>
    <cfset this.applicationTimeout = createTimespan(1,0,0,0)>
    <cfset this.datasource = "projectmanagementdb">

    <cffunction name="onApplicationStart" access="public" returnType="boolean" output="false">
        <cfset application.siteName = "Task Flow App">
        <cfset application.startTime = now()>
        <cfset application.DBS = this.datasource>

        <cfset application.mail = {
            server = "smtp.gmail.com",
            port = 587,
            username = "bobby43n7@gmail.com",
            password = "gcpsnpomersozzkp"
        }>

        <cfreturn true>
        
    </cffunction>

    <cffunction  name="onSessionStart" access="public" returnType="void">
        <cfset session.isLoggedIn = false>
        <cfset session.user = structNew()>
        <cfset session.lastActivity = now()>
        <cfset session.csrfToken = createUUID()>
    </cffunction>
    

    <cffunction name="onRequestStart" access="public" returnType="boolean">
        <cfargument name="targetPage" type="string" required="true">

        <cfset allowedPages = "login.cfm,register.cfm,UserService.cfc,terms.cfm">
        <cfset currentPage = getFileFromPath(arguments.targetPage)>


        <cfif structKeyExists(session, "isLoggedIn")>
            <cfset session.lastActivity = now()>
        </cfif>

        <cfif NOT StructKeyExists(application, "DBS")>
            <cfset application.DBS = this.datasource>
        </cfif>

        <cfif NOT listFindNoCase(allowedPages, currentPage)>
            <cfif NOT structKeyExists(session, "isLoggedIn")
                OR NOT session.isLoggedIn>
                <cflocation url="/taskflow/login.cfm" addtoken="false">
            </cfif>
        </cfif>
        <cfreturn true>
    </cffunction>

    <!--- <cffunction name="onError" access="public" returnType="void">
        <cfargument name="Exception" required="true">
        <cfargument name="EventName" required="true">

        <cflog file="#this.name#" type="error" text="Event Name: #Arguments.EventName#">
        <cflog file="#this.name#" type="error" text="Message: #Arguments.Exception.message#">
        <cflog file="#this.name#" type="error" text="Error Type: #Arguments.Exception.type#">
        <cfif structKeyExists(Arguments.Exception, "rootCause") AND structKeyExists(Arguments.Exception.rootCause, "message")>
            <cflog file="#this.name#" type="error" text="Root Cause: #Arguments.Exception.rootCause.message#">
        </cfif>
        <cfif structKeyExists(Arguments.Exception, "tagContext") AND arrayLen(Arguments.Exception.tagContext) GT 0>
            <cflog file="#this.name#" type="error" text="Stack Trace: #Arguments.Exception.tagContext[1].template#:#Arguments.Exception.tagContext[1].line#">
        </cfif>

    </cffunction>  --->

</cfcomponent>