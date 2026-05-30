<cfcomponent displayname="Project Service" output="false">

    <cffunction name="validateProjectData" access="private" returntype="string" output="false">

        <cfargument name="ProjectName" type="string" required="true">
        <cfargument name="Description" type="string" required="true">
        <cfargument name="StartDate" type="string" required="false">
        <cfargument name="DueDate" type="string" required="false">
        <cfargument name="ProjectStatus" type="string" required="false">

        <cfif len(trim(arguments.ProjectName)) LT 3>
            <cfreturn "Project name is required and must be at least 3 characters." />
        </cfif>

        <cfif len(trim(arguments.Description)) LT 10>
            <cfreturn "Description is required and must be at least 10 characters." />
        </cfif>

        <cfif arguments.StartDate NEQ "" AND NOT isValid("date", arguments.StartDate)>
            <cfreturn "Invalid start date format." />
        </cfif>

        <cfif arguments.DueDate NEQ "" AND NOT isValid("date", arguments.DueDate)>
            <cfreturn "Invalid due date format." />
        </cfif>

        <cfif arguments.StartDate GT arguments.DueDate>
            <cfreturn "Start date cannot be later than due date." />
        </cfif>

        <cfif arguments.ProjectStatus NEQ "" AND NOT listFind("Pending,In Progress,Completed", arguments.ProjectStatus)>
            <cfreturn "Invalid project status." />
        </cfif>

        <cfreturn "">
    </cffunction>

    <cffunction name="addProject" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="ProjectName" type="string" required="true">
        <cfargument name="Description" type="string" required="true">
        <cfargument name="StartDate" type="string" required="true">
        <cfargument name="DueDate" type="string" required="true">
        <cfargument name="ProjectStatus" type="string" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset userID = session.user.id>

        <cfset validationError = validateProjectData(
                                    arguments.ProjectName, 
                                    arguments.Description, 
                                    arguments.StartDate, 
                                    arguments.DueDate, 
                                    arguments.ProjectStatus)>

        <cfif validationError NEQ "">
            <cfreturn { "status":"error", "message":validationError }>
        </cfif>
       
        <cftry>
            <cfquery datasource="#application.DBS#">
                INSERT INTO dbo.projects (user_id, project_name, description, start_date, end_date, project_status) 
                VALUES (
                    <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.ProjectName#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#arguments.Description#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#arguments.StartDate#" cfsqltype="cf_sql_date">,
                    <cfqueryparam value="#arguments.DueDate#" cfsqltype="cf_sql_date">,
                    <cfqueryparam value="#arguments.ProjectStatus#" cfsqltype="cf_sql_nvarchar">
                )
            </cfquery>

            <cfreturn { "status":"success", "message":"Project added successfully" }>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Failed to add project" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getProjects" access="remote" returntype="struct" returnformat = "json" output="false">
        <cfset userID = session.user.id>

        <cftry>
            <cfquery name="getUserProjects" datasource="#application.DBS#">
                SELECT project_id, project_name, description, start_date, end_date, project_status 
                FROM dbo.projects
                WHERE user_id = <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">
                ORDER BY CreatedAt DESC
            </cfquery>

            <cfif getUserProjects.recordCount EQ 0>
                <cfreturn { "status":"success", "projects": [] }>
            <cfelse>
                <cfset projectsArray = []>
                <cfloop query="getUserProjects">
                    <cfset projectStruct = {
                        "project_id": getUserProjects.project_id,
                        "project_name": getUserProjects.project_name,
                        "description": getUserProjects.description,
                        "start_date": dateFormat(getUserProjects.start_date, "yyyy-mm-dd"),
                        "due_date": dateFormat(getUserProjects.end_date, "yyyy-mm-dd"),
                        "project_status": getUserProjects.project_status
                    }>
                    <cfset arrayAppend(projectsArray, projectStruct)>
                </cfloop>
                <cfreturn { "status":"success", "projects": projectsArray }>
            </cfif>

        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Failed to retrieve projects" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction  name="deleteProject" access = "remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="projectID" type="numeric" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset userID = session.user.id>

        <cftry>
            <cfquery datasource="#application.DBS#">
                DELETE FROM dbo.projects
                WHERE project_id = <cfqueryparam value="#arguments.projectID#" cfsqltype="cf_sql_integer">
                AND user_id = <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfreturn { "status":"success", "message":"Project deleted successfully" }>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Failed to delete project" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction  name="getProjectId" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="projectID" type="numeric" required="true">
        <cfset userID = session.user.id>

        <cftry>
            <cfquery name="getProject" datasource="#application.DBS#">
                SELECT project_id, project_name, description, start_date, end_date, project_status 
                FROM dbo.projects
                WHERE project_id = <cfqueryparam value="#arguments.projectID#" cfsqltype="cf_sql_integer">
                AND user_id = <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfif getProject.recordCount EQ 0>
                <cfreturn { "status":"error", "message":"Project not found" }>
            <cfelse>
                <cfset projectStruct = {
                    "project_id": getProject.project_id[1],
                    "project_name": getProject.project_name[1],
                    "description": getProject.description[1],
                    "start_date": dateFormat(getProject.start_date[1], "yyyy-mm-dd"),
                    "due_date": dateFormat(getProject.end_date[1], "yyyy-mm-dd"),
                    "project_status": getProject.project_status[1]
                }>
                <cfreturn { "status":"success", "project": projectStruct }>
            </cfif>

        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Failed to retrieve project details" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction  name="updateProjectDetails" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="projectID" type="numeric" required="true">
        <cfargument name="ProjectName" type="string" required="true">
        <cfargument name="Description" type="string" required="true">
        <cfargument name="StartDate" type="string" required="true">
        <cfargument name="DueDate" type="string" required="true">
        <cfargument name="ProjectStatus" type="string" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset userID = session.user.id>

        <cfset validationError = validateProjectData(
                                    arguments.ProjectName, 
                                    arguments.Description, 
                                    arguments.StartDate, 
                                    arguments.DueDate, 
                                    arguments.ProjectStatus)>

        <cfif validationError NEQ "">
            <cfreturn { "status":"error", "message":validationError }>
        </cfif>

        <cftry>
            <cfquery datasource="#application.DBS#">
                UPDATE dbo.projects
                SET 
                    project_name = <cfqueryparam value="#arguments.ProjectName#" cfsqltype="cf_sql_nvarchar">,
                    description = <cfqueryparam value="#arguments.Description#" cfsqltype="cf_sql_nvarchar">,
                    start_date = <cfqueryparam value="#arguments.StartDate#" cfsqltype="cf_sql_date">,
                    end_date = <cfqueryparam value="#arguments.DueDate#" cfsqltype="cf_sql_date">,
                    project_status = <cfqueryparam value="#arguments.ProjectStatus#" cfsqltype="cf_sql_nvarchar">
                WHERE project_id = <cfqueryparam value="#arguments.projectID#" cfsqltype="cf_sql_integer">
                AND user_id = <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfreturn { "status":"success", "message":"Project updated successfully" }>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Failed to update project details" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getProjectStatusCounts" access="remote" returntype="struct" returnformat="json" output="false">
        <cfset userID = session.user.id>
        <cftry>
            <cfquery name="projectCounts" datasource="#application.DBS#">
                SELECT 
                    COUNT(*) AS totalProjects,
                    SUM(CASE WHEN project_status = 'Pending' THEN 1 ELSE 0 END) AS pendingCount,
                    SUM(CASE WHEN project_status = 'In Progress' THEN 1 ELSE 0 END) AS inProgressCount,
                    SUM(CASE WHEN project_status = 'Completed' THEN 1 ELSE 0 END) AS completedCount
                FROM dbo.projects WHERE user_id = <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset ProjectCounts = {
                "totalProjects": projectCounts.totalProjects,
                "pendingCount": projectCounts.pendingCount,
                "inProgressCount": projectCounts.inProgressCount,
                "completedCount": projectCounts.completedCount
            }>  

            <cfquery name="projectTasksCounts" datasource="#application.DBS#">
                SELECT
                    COUNT(*) AS totalTasks,
                    SUM(CASE WHEN dbo.tasks.status = 'Pending' THEN 1 ELSE 0 END) AS pendingCount,
                    SUM(CASE WHEN dbo.tasks.status = 'In Progress' THEN 1 ELSE 0 END) AS inProgressCount,
                    SUM(CASE WHEN dbo.tasks.status = 'Completed' THEN 1 ELSE 0 END) AS completedCount
                FROM dbo.tasks JOIN dbo.projects ON dbo.tasks.project_id = dbo.projects.project_id
                WHERE dbo.projects.user_id = <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset projectTasksCounts = {
                "totalTasks": projectTasksCounts.totalTasks,
                "pendingCount": projectTasksCounts.pendingCount,
                "inProgressCount": projectTasksCounts.inProgressCount,
                "completedCount": projectTasksCounts.completedCount
            }>

            <cfreturn { "status":"success", "projectCounts": ProjectCounts, "projectTasksCounts": projectTasksCounts }>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" 
                type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Failed to retrieve project status counts" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="addProjectCount" access="remote" returntype="query" output="false">
        <cfargument name="projectID" type="numeric" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfset result = {}>
        <cfset userID = session.user.id>
        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cftry>
            <cfquery name="projectViewCount" datasource="#application.DBS#">
                UPDATE dbo.projects 
                SET view_count = view_count + 1
                WHERE project_id = <cfqueryparam value="#arguments.projectID#" cfsqltype="cf_sql_integer">
                AND user_id = <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfreturn { "status":"success", "message":"View count updated" }>
        <cfcatch type="any">
            <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
            <cfreturn { "status":"error", "message":"Failed to update view count" }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="getProjectViewCount" access="remote" returntype="query" output="false">
        <cfset userID = session.user.id>

        <cftry>
            <cfquery name="getViewCount" datasource="#application.DBS#">
                SELECT TOP 3 project_id, project_name, project_status, view_count
                FROM dbo.projects 
                WHERE user_id = <cfqueryparam value="#userID#" cfsqltype="cf_sql_integer">
                ORDER BY view_count DESC
            </cfquery>
            <cfreturn getViewCount>

            <cfcatch type="any">
                <cflog file="taskflow_bugs" type="error" text="#cfcatch.message# | #cfcatch.detail#">
                <cfset result = { "status" : "error", "message" : "Server Error: Could not retrieve project view counts" }>
            </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    
</cfcomponent>