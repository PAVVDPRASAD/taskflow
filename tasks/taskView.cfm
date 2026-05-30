<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tasks - TaskFlow</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
    <link rel="stylesheet" href="/taskflow/styles.css">
</head>

<cfset projectId = encodeForHTML(url.project_id)>
<cfset projectName = encodeForHTML(url.project_name)>
<cfif StructKeyExists(session.user, "profilePhoto") AND Len(session.user.profilePhoto) AND session.user.profilePhoto NEQ "/taskflow/assets/images/profile-logo.png">
    <cfset profilePhotoUrl = "/taskflow/assets/images/#encodeForURL(session.user.profilePhoto)#">
<cfelse>
    <cfset profilePhotoUrl = "/taskflow/assets/images/profile-logo.png">
</cfif>

<body class="bg-light">
    <div class="container d-flex justify-content-between align-items-center mt-3">
        <a href="/taskflow/dashboard.cfm" class="btn btn-primary btn-sm">
            <i class="fa-solid fa-arrow-left"></i> Back
        </a>
        <a href="#" id="userProfileLink">
            <cfoutput>
                <div class="d-flex align-items-center">
                    <img src="#profilePhotoUrl#" alt="User Icon" class="rounded-circle" width="40" height="40">
                    <span class="ms-2 mb-0 text-dark fw-semibold fs-5 d-none d-lg-block">#encodeForHTML(session.user.FullName)#</span>
                </div>
            </cfoutput>
        </a>
    </div>
    <hr class="border border-muted border-1"/>
    <div class="container">
        <div class="container mt-4">
            <cfoutput>
                <h3 class="mb-5 fs-2 text-secondary font-bold">#projectName#</h3>
            </cfoutput>
            
            <div class="container my-5 d-flex justify-content-between align-items-center">
                <h4 class="mb-4 text-secondary">Task Modules:</h4>
                <button class="btn btn-primary" id="addTaskBtn" data-bs-toggle="modal" data-bs-target="#addTaskModal">
                    <i class="fa-solid fa-plus"></i> Add Task
                </button>
            </div>
            <div id="tasksContainer" class="row "></div>
        </div>
    </div>

    <input type="hidden" id="csrfToken" name="csrfToken" value="<cfoutput>#session.csrfToken#</cfoutput>">
    

    <div class="modal fade" id="addTaskModal" tabindex="-1" aria-labelledby="addTaskModalLabel">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="addTaskModalLabel">Add Task</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form id="taskForm" method="post" enctype="multipart/form-data">
                        <input type="hidden" id="taskId" name="taskId" />
                        <div class="form-floating mb-3">
                            <input type="text" class="form-control" name="taskName" id="taskName">
                            <label for="taskName" class="form-label">Task Name</label>
                            <small class="form-text text-muted d-block mb-3">Minimum 3 characters, maximum 50 characters</small>
                        </div>
                        <div class="mb-3">
                            <textarea class="form-control" name="taskDescription" id="taskDescription" rows="3" placeholder="Enter task description"></textarea>
                            <small class="form-text text-muted d-block mb-3">Minimum 10 characters, maximum 500 characters</small>
                        </div>
                        
                        <div class="form-floating col-md-6 mb-3">
                            <input type="date" class="form-control" name="dueDate" id="taskEndDate">
                            <label for="taskEndDate" class="form-label">Due Date</label>
                        </div>

                        <div class="form-floating col-md-6 mb-3">
                            <select class="form-select" name="taskStatus" id="taskStatus">
                                <option value="" selected>Select status</option>
                                <option value="Pending">Pending</option>
                                <option value="In Progress">In Progress</option>
                                <option value="Completed">Completed</option>
                            </select>
                            <label for="taskStatus" class="form-label">Status</label>
                        </div>
                        <div class="mb-3">
                            <label for="taskFile" class="form-label">Attach File (optional)</label>
                            <input type="file" class="form-control" name="filePath" id="taskFile" accept=".pdf,.docx,.xlsx,.png,.jpg,.jpeg">
                        </div>
                        <small class="form-text text-muted d-block mb-3">Supported formats: PDF, DOCX, XLSX, PNG, JPG, JPEG</small>
                        <div id="taskFormError" class="alert alert-danger d-none mt-3" role="alert"></div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" id="saveTaskBtn">Save Task</button>
                </div>
            </div>
        </div>
    </div>

    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="/taskflow/assets/utils.js"></script>
    <script src="/taskflow/assets/tasks.js"></script>
    
</body>
</html>