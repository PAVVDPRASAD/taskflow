<cfcomponent displayname="Task Service" output="false">

    <cffunction name="validateTaskData" access="private" returntype="string" output="false">
        <cfargument name="taskName" type="string" required="true">
        <cfargument name="taskDescription" type="string" required="true">
        <cfargument name="taskStatus" type="string" required="true">
        <cfargument name="dueDate" type="date" required="true">

        <cfif len(arguments.taskName) LTE 3>
            <cfreturn "Task name must be at least 3 characters long.">
        </cfif>

        <cfif len(trim(arguments.taskDescription)) LT 10>
            <cfreturn "Task description must be at least 10 characters long.">
        </cfif>

        <cfset validStatuses = ["Pending", "In Progress", "Completed"]>
        <cfif NOT arrayContains(validStatuses, arguments.taskStatus)>
            <cfreturn "Invalid task status. Must be 'Pending', 'In Progress', or 'Completed'.">
        </cfif>

        <cfif arguments.dueDate EQ "" OR NOT isDate(arguments.dueDate)>
            <cfreturn "Due date is required and must be a valid date.">
        </cfif>

        <cfreturn "">
    </cffunction>

    <cffunction name="addTask" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="taskName" type="string" required="true">
        <cfargument name="taskDescription" type="string" required="true">
        <cfargument name="dueDate" type="string" required="true">
        <cfargument name="taskStatus" type="string" required="true">
        <cfargument name="filePath" type="any" required="false" default="">
        <cfargument name="projectId" type="numeric" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset result = {}>

        <cfset parsedDate = parseDateTime(arguments.dueDate)>

        <cfset validatedData = validateTaskData(arguments.taskName, arguments.taskDescription, arguments.taskStatus, parsedDate)>
        <cfif len(validatedData) GT 0>
            <cfset result = {"status":"error", "message":validatedData}>
            <cfreturn result>
        </cfif>

        <cfset filePathValue = "">

        <cfif structKeyExists(form, "filePath") AND len(form.filePath)>

            <cffile action="upload" 
                    destination="#expandPath('/taskflow/uploads/')#"
                    filefield="filePath"
                    nameconflict="makeunique"
                    result="uploadResult">

            <cfset filePathValue = uploadResult.serverFile>

        </cfif>

        <cfquery name="checkProjectOwnership" datasource="#application.DBS#">
            SELECT project_id 
            FROM dbo.projects 
            WHERE project_id = <cfqueryparam value="#arguments.projectId#" cfsqltype="cf_sql_integer">
            AND user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif checkProjectOwnership.recordCount EQ 0>
            <cfreturn { "status" : "error", "message" : "Project not found or you do not have permission to add tasks to it." }>
        </cfif>


        <cftry>
            <cfquery datasource="#application.DBS#">
                INSERT INTO dbo.tasks (project_id, title, task_description, status, due_date, file_path)
                VALUES (
                    <cfqueryparam value="#arguments.projectId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#arguments.taskName#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#arguments.taskDescription#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#arguments.taskStatus#" cfsqltype="cf_sql_nvarchar">,
                    <cfqueryparam value="#parsedDate#" cfsqltype="cf_sql_date">,
                    <cfqueryparam value="#filePathValue#" cfsqltype="cf_sql_nvarchar">
                )
            </cfquery>

            <cfset result = { "status" : "success", "message" : "Task added successfully." }>
        <cfcatch>
            <cflog text="Error adding task: #cfcatch.message# | Detail: #cfcatch.detail#" file="taskflow_bugs" type="error">
            <cfset result = { "status" : "error", "message" = "Database error: Something went wrong." }>
        </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>


    <cffunction name="getTaskModules" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="projectId" type="numeric" required="true">
        <cfset userId = session.user.id>
        
        <cftry>
            <cfquery name="getTasks" datasource="#application.DBS#">
                SELECT task_id, project_id, title, task_description, status, due_date, file_path
                FROM dbo.tasks
                WHERE project_id = <cfqueryparam value="#arguments.projectId#" cfsqltype="cf_sql_integer">
                AND project_id IN (
                    SELECT project_id FROM dbo.projects
                    WHERE user_id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
                )
            </cfquery>

            <cfset result = []>
            <cfloop query="getTasks">
                <cfset task = {
                    task_id = getTasks.task_id,
                    project_id = getTasks.project_id,
                    title = getTasks.title,
                    task_description = getTasks.task_description,
                    status = getTasks.status,
                    due_date = getTasks.due_date,
                    file_path = getTasks.file_path
                }>
                <cfset arrayAppend(result, task)>
            </cfloop>

            <cfreturn { "status" : "success", "data" : result }>
        <cfcatch>
            <cflog text="Error fetching tasks: #cfcatch.message#" file="taskflow_bugs" type="error">
            <cfreturn { "status" : "error", "message" : "Failed to fetch tasks." }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="deleteTask" access="remote" returntype="struct" returnformat="json" output="false">
    
        <cfargument name="taskId" type="numeric" required="true">
        <cfargument name="projectId" type="numeric" required="true">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset var userId = session.user.id>
        <cfset var deleteResult = {}>

        <cftry>
            <cfquery name="deleteTaskQuery" datasource="#application.DBS#" result="deleteResult">
                DELETE t
                FROM dbo.tasks t
                INNER JOIN dbo.projects p 
                    ON t.project_id = p.project_id
                WHERE t.task_id = <cfqueryparam value="#arguments.taskId#" cfsqltype="cf_sql_integer">
                AND t.project_id = <cfqueryparam value="#arguments.projectId#" cfsqltype="cf_sql_integer">
                AND p.user_id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfif deleteResult.recordCount GT 0>
                <cfreturn { "status" : "success", "message" : "Task deleted successfully." }>
            <cfelse>
                <cfreturn { "status" : "error", "message" : "Task not found or unauthorized." }>
            </cfif>

        <cfcatch>
            <cflog text="Error deleting task: #cfcatch.message# | Detail: #cfcatch.detail#" file="taskflow_bugs" type="error">
            <cfreturn { "status" : "error", "message" : "Failed to delete task." }>
        </cfcatch>
        </cftry>
    </cffunction>


    <cffunction name="getTaskById" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="taskId" type="numeric" required="true">
        <cfargument name="projectId" type="numeric" required="true">

        <cfset userId = session.user.id>
        <cftry>
            <cfquery name="getTask" datasource="#application.DBS#">
                SELECT 
                    t.task_id,
                    t.project_id,
                    t.title,
                    t.task_description,
                    t.status,
                    t.due_date,
                    t.file_path
                FROM dbo.tasks t
                INNER JOIN dbo.projects p 
                    ON t.project_id = p.project_id
                WHERE t.task_id = <cfqueryparam value="#arguments.taskId#" cfsqltype="cf_sql_integer">
                AND t.project_id = <cfqueryparam value="#arguments.projectId#" cfsqltype="cf_sql_integer">
                AND p.user_id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfif getTask.recordCount EQ 0>
                <cfreturn { "status" : "error", "message" : "Task not found or you do not have permission to view it." }>
            </cfif>

            <cfset task = {
                "task_id" : getTask.task_id,
                "project_id" : getTask.project_id,
                "title" : getTask.title,
                "task_description" : getTask.task_description,
                "status" : getTask.status,
                "due_date" : dateFormat(getTask.due_date, 'yyyy-mm-dd'),
                "file_path" : getTask.file_path
            }>

            <cfreturn { "status": "success", "data": task }>
        <cfcatch>
            <cflog text="Error fetching task: #cfcatch.message#" file="taskflow_bugs" type="error">
            <cfreturn { "status": "error", "message": "Failed to fetch task." }>
        </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="updateTask" access="remote" returntype="struct" returnformat="json" output="false">
        <cfargument name="taskId" type="numeric" required="true">
        <cfargument name="taskName" type="string" required="true">
        <cfargument name="taskDescription" type="string" required="true">
        <cfargument name="dueDate" type="string" required="true">
        <cfargument name="taskStatus" type="string" required="true">
        <cfargument name="filePath" type="any" required="false" default="">
        <cfargument name="csrfToken" type="string" required="true">

        <cfif arguments.csrfToken NEQ session.csrfToken>
            <cfreturn { "status":"error", "message":"Invalid CSRF token" }>
         </cfif>

        <cfset result = {}>
        <cfset parsedDate = parseDateTime(arguments.dueDate)>

        <cfset validatedData = validateTaskData(arguments.taskName, arguments.taskDescription, arguments.taskStatus, parsedDate)>
        <cfif len(validatedData) GT 0>
            <cfset result = { "status": "error", "message": validatedData }>
            <cfreturn result>
        </cfif>

        <cfset oldFilePath = "">
        <cfset oldFileName ="">

        <cftry>
            <cfquery name="getOldFilePath" datasource="#application.DBS#">
                SELECT t.file_path
                FROM dbo.tasks t
                JOIN dbo.projects p ON t.project_id = p.project_id
                WHERE t.task_id = <cfqueryparam value="#arguments.taskId#" cfsqltype="cf_sql_integer">
                AND p.user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif getOldFilePath.recordCount EQ 0>
                <cfreturn { "status" : "error", "message" : "Task not found or you do not have permission to update it." }>
            </cfif>
            <cfset oldFileName = getOldFilePath.file_path>
            <cfset oldFilePath = expandPath("/taskflow/uploads/#oldFileName#")>
            <cfcatch type="any">
                <cfreturn { "status" : "error", "message" : "Failed to fetch old file path or check ownership." }>
            </cfcatch>
        </cftry>

        
        <cftry>
            <cfset filePathValue = oldFileName>
            
            <cfif structKeyExists(form, "filePath") AND len(form.filePath)>
                
                <cffile action="upload" 
                        destination="#expandPath('/taskflow/uploads/')#"
                        filefield="filePath"
                        nameconflict="makeunique"
                        result="uploadResult">
                <cfset filePathValue = uploadResult.serverFile>

                <cfif len(oldFilePath) GT 0 AND fileExists(oldFilePath)>
                    <cffile action="delete" file="#oldFilePath#">
                </cfif>
            
            </cfif>

            <cfquery datasource="#application.DBS#">
                UPDATE dbo.tasks
                SET 
                    title = <cfqueryparam value="#arguments.taskName#" cfsqltype="cf_sql_nvarchar">,
                    task_description = <cfqueryparam value="#arguments.taskDescription#" cfsqltype="cf_sql_nvarchar">,
                    status = <cfqueryparam value="#arguments.taskStatus#" cfsqltype="cf_sql_nvarchar">,
                    due_date = <cfqueryparam value="#parsedDate#" cfsqltype="cf_sql_date">
                    <cfif len(filePathValue) GT 0>
                        , file_path = <cfqueryparam value="#filePathValue#" cfsqltype="cf_sql_nvarchar">
                    </cfif>
                WHERE task_id = <cfqueryparam value="#arguments.taskId#" cfsqltype="cf_sql_integer">
                AND project_id IN (
                    SELECT project_id FROM dbo.projects
                    WHERE user_id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
                )
            </cfquery>

            <cfset result = { "status": "success", "message": "Task updated successfully." }>
            <cflog text="Task updated successfully." file="taskflow_bugs" type="info">
        <cfcatch>
            <cflog text="Error updating task: #cfcatch.message# | Detail: #cfcatch.detail#" file="taskflow_bugs" type="error">
            <cfset result = { "status": "error", "message": "Database error: Something went wrong." }>
        </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

</cfcomponent>