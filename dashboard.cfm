<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TaskFlow - Dashboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="./styles.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
</head>
<body>
    <cfset projectService = createObject("component", "components.ProjectService")>
    <cfset getViewCount = projectService.getProjectViewCount()>

    <cfif StructKeyExists(session, "user")
            AND StructKeyExists(session.user, "profilePhoto")
            AND Len(Trim(session.user.profilePhoto))
            AND session.user.profilePhoto NEQ "profile-logo.png">

        <cfset profilePhotoUrl = "/taskflow/assets/images/#session.user.profilePhoto#">
    <cfelse>
        <cfset profilePhotoUrl = "/taskflow/assets/images/profile-logo.png">
    </cfif>

    <input type="hidden" name="csrfToken" id="csrfToken" value="<cfoutput>#session.csrfToken#</cfoutput>">


    <nav class="sidebar collapse d-lg-block bg-light shadow border-end">
        <div class="p-3">
            <img src="/taskflow/assets/logo/logo-text.webp" alt="TaskFlow Logo" class="logo-img" />
            
            <ul class="nav d-flex flex-column justify-content-between align-items-start h-100">
                <div class="nav flex-column mb-3">
                    <li class="nav-item">
                        <a class="nav-link active" href="#" id="dashboardLink"> <i class="fa-solid fa-home"></i> Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="#" id="projectListLink"> <i class="fa-solid fa-folder"></i> All Projects</a>
                    </li>
                </div>
                <hr class="w-100">
                <li class="nav-item">
                    <a class="nav-link" href="#" id="logoutBtn"> <i class="fa-solid fa-sign-out-alt"></i> Logout</a>
                </li>
            </ul>
        </div>
    </nav>

    <div class="main-content">
        <nav class="navbar navbar-light bg-white shadow-sm sticky-top">
            <div class="container-fluid">
                <button class="btn btn-light hamburger-btn" type="button" data-bs-toggle="collapse" data-bs-target=".sidebar">
                    <span class="navbar-toggler-icon"></span>
                </button>
                <span class="navbar-text" id="pageTitle">Dashboard</span>
                <a class="nav-link" href="#" id="userProfileLink"> 
                    <cfoutput>
                        <div class="d-flex align-items-center">
                            <img src="#profilePhotoUrl#" alt="User Icon" class="rounded-circle" width="40" height="40">
                            <span class="ms-2 mb-0 text-dark fw-semibold fs-5 d-none d-lg-block">#encodeForHTML(session.user.FullName)#</span>
                        </div>
                    </cfoutput> 
                </a>
            </div>
        </nav>

        <div class="container-fluid p-4">
            <div id="dashboardSection">
                
                    <div class="my-5 py-5 text-center">
                        <cfoutput>
                        <h2 class="text-dark fs-1 fw-bold">Welcome back, #encodeForHTML(session.user.FullName)#</h2>
                        </cfoutput>
                        <p class="mb-4 text-secondary">Here is your workspace summary and recent activity.</p>
                        <button class="btn btn-primary" id="addProjectBtnTop" data-bs-toggle="modal" data-bs-target="#projectModal">
                            Add Project
                        </button>
                    </div>
                
               
                    <div class="row mb-4">
                        <div class="col-12 mb-3">
                            <div class="h-100">
                                <div class="d-flex flex-column flex-lg-row justify-content-around align-items-center mb-3">
                                    <div class="d-flex justify-content-center align-items-center gap-4 flex-wrap">
                                        <div class="chart-container"><canvas id="projectsChart"></canvas></div>
                                        <div class="chart-container"><canvas id="tasksChart"></canvas></div>
                                    </div>
                                    <div class="my-5">
                                        <h4 class="mb-5 text-dark fw-semibold fs-4 text-center">Top Viewed Projects:</h4>
                                        <cfoutput query="getViewCount">
                                            <div class="project-timeline d-flex justify-content-center align-items-center gap-4 flex-wrap p-3">
                                                <div class="timeline-dot"></div>
                                                <div class="timeline-item card text-center shadow-sm 
                                                    <cfif getViewCount.project_status EQ "Completed">
                                                        success-banner
                                                    <cfelseif getViewCount.project_status EQ "In Progress">
                                                        info-banner
                                                    <cfelseif getViewCount.project_status EQ "Pending">
                                                        warning-banner
                                                    </cfif>">
                                                    <div class="timeline-card card-body">
                                                        <h5 class="card-title">#encodeForHTML(project_name)#</h5>
                                                    </div>
                                                </div>
                                            </div>
                                        </cfoutput>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                

                <div class="d-flex justify-content-between align-items-center my-3">
                    <h4 class="mb-3">Recent Projects:</h4>
                    <button class="btn btn-primary btn-sm" id="addProjectBtnTop" data-bs-toggle="modal" data-bs-target="#projectModal">
                        <i class="fa-solid fa-plus"></i> Add Project
                    </button>
                </div>
                <div id="projectsList" class="row">
                    <div class="col-12 text-center">
                        <div class="spinner-border text-primary" role="status">
                            <span class="visually-hidden">Loading...</span>
                        </div>
                    </div>
                </div>
            </div>

            <div id="projectsSection" style="display:none;">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h2 class="mb-4">All Projects</h2>
                    <button class="btn btn-primary btn-sm" id="addProjectBtnBottom" data-bs-toggle="modal" data-bs-target="#projectModal">
                        <i class="fa-solid fa-plus"></i> Add Project
                    </button>
                </div>
                <div id="projectsListFull" class="row">
                    <div class="col-12 text-center">
                        <div class="spinner-border text-primary" role="status">
                            <span class="visually-hidden">Loading...</span>
                        </div>
                    </div>
                </div>
            </div>

           <div id="profileSection" style="display:none;">
                <h2 class="my-5 text-center">User Profile</h2>
            <div class="row justify-content-center">
                <div class="col-12 col-md-6">
                    <div class="card shadow-sm">
                        <div class="card-body d-flex flex-column align-items-center">
                        <cfoutput> 
                            <form id="profileForm" method="post" enctype="multipart/form-data" class="w-100">
                                <div class="profile-picture-container d-flex flex-column align-items-center">
                                    <img alt="Profile Picture"
                                         src="#profilePhotoUrl#"
                                         id="profilePhotoPreview"    
                                         class="profile-photo mb-3" />
                                    <input type="file" id="profilePhotoInput" name="ProfilePhoto" 
                                           accept=".jpg,.jpeg,.png" 
                                           class="d-none">
                                    <button type="button" class="profile-edit-btn mb-4" id="changePhotoBtn">
                                        <i class="fa-solid fa-camera shadow fw-bold"></i>
                                    </button>
                                </div>
                                <input type="hidden" id="profileUserId" value="#encodeForHTML(session.user.id)#">
                                <div id="profileFormError" class="alert alert-danger d-none"></div>
                                <div class="mb-3">
                                    <label class="form-label">Name</label>
                                    <input type="text" id="fullName" name="FullName" class="form-control" value="#encodeForHTML(session.user.FullName)#" disabled>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Username</label>
                                    <input type="text" class="form-control" value="#encodeForHTML(session.user.username)#" disabled>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Email</label>
                                    <input type="email" id="email" name="Email" class="form-control" value="#encodeForHTML(session.user.email)#" disabled>
                                </div>
                                <div class="mb-3 d-none" id="currentPasswordFields">
                                    <label class="form-label">Current Password</label>
                                    <input type="password" id="currentPassword" class="form-control" placeholder="Enter current password">
                                </div>
                                <div class="mb-3 d-none" id="passwordFields">
                                    <label class="form-label">New Password</label>
                                    <input type="password" id="newPassword" class="form-control" placeholder="Enter new password">
                                </div>
                                <div class="mb-3 d-none" id="confirmPasswordFields">
                                    <label class="form-label">Confirm New Password</label>
                                    <input type="password" id="confirmNewPassword" class="form-control" placeholder="Confirm new password">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Mobile Phone</label>
                                    <input type="tel" id="phoneNumber" name="PhoneNumber" class="form-control" value="#encodeForHTML(session.user.phoneNumber)#" disabled>
                                </div>
                                
                                <div class="d-flex justify-content-end gap-2">
                                    <button type="button" class="btn btn-secondary" id="cancelBtn">Cancel</button>
                                    <button type="button" class="btn btn-success " id="saveBtn">Save</button>
                                    <button type="button" class="btn btn-outline-secondary " id="changePasswordBtn">Change Password</button>
                                    <button type="button" class="btn btn-primary" id="editBtn">Edit</button>
                                </div>
                            </form>
                        </cfoutput>
                        </div>
                    </div>
                </div>
            </div>
            </div>
        </div>
    </div>

    <div class="modal fade" id="projectModal" tabindex="-1" aria-labelledby="projectModalLabel">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="projectModalLabel">Add Project</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                </div>
                <div class="modal-body">
                    <form id="projectForm">
                        <input type="hidden" id="projectId" />
                        <div class="mb-3 form-floating">
                            <input type="text" class="form-control" name="ProjectName" id="projectName" placeholder="Project Name">
                            <label for="projectName" class="form-label">Project Name</label>
                            <small class="form-text text-muted d-block mb-3">Minimum 3 characters, maximum 50 characters</small>
                        </div>
                        <div class="mb-3 form-floating">
                            <textarea class="form-control" name="Description" id="projectDescription" rows="3" placeholder="Enter project description"></textarea>
                            <label for="projectDescription" class="form-label">Description</label>
                            <small class="form-text text-muted d-block mb-3">Minimum 10 characters, maximum 500 characters</small>
                        </div>
                        <div class="row">
                            <div class="form-floating col-md-6 mb-3">
                                <input type="date" class="form-control" name="StartDate" id="projectStartDate">
                                <label for="projectStartDate" class="form-label">Start Date</label>
                            </div>
                            <div class="form-floating col-md-6 mb-3">
                                <input type="date" class="form-control" name="DueDate" id="projectEndDate">
                                <label for="projectEndDate" class="form-label">End Date</label>
                            </div>
                        </div>
                        <div class="mb-3 form-floating">
                            <select class="form-select" name="ProjectStatus" id="projectStatus">
                                <option value="" selected>Select status</option>
                                <option value="Pending">Pending</option>
                                <option value="In Progress">In Progress</option>
                                <option value="Completed">Completed</option>
                            </select>
                            <label for="projectStatus" class="form-label">Status</label>
                        </div>
                        <div id="projectFormError" class="alert alert-danger d-none mt-3" role="alert"></div>
                    </form>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" id="saveProjectBtn">Save Project</button>
                </div>
            </div>
        </div>
    </div>


    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="./assets/utils.js"></script>
    <script src="./assets/projects.js"></script>
    <script src="./assets/tasks.js"></script>
    <script src="./assets/users.js"></script>
</body>
</html>