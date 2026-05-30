let isEditMode = false;
let currentProjectId = null;
let allProjects = [];


function editProject(event, projectId){
    event.preventDefault();
    $.ajax({
        url: "/taskflow/components/ProjectService.cfc?method=getProjectId",
        type: "GET",
        data: { projectID: projectId },
        dataType: "json",
        success: function(res) {
            if(res.status === "success") {
                let p = res.project;

                $("#projectName").val(p.project_name || p.PROJECT_NAME);
                $("#projectDescription").val(p.description || p.DESCRIPTION);
                $("#projectStartDate").val(p.start_date || p.START_DATE);
                $("#projectEndDate").val(p.due_date || p.DUE_DATE);
                $("#projectStatus").val(p.project_status || p.PROJECT_STATUS);
                $("#projectId").val(projectId);
                $("#projectModalLabel").text("Edit Project");
                isEditMode = true;
                currentProjectId = projectId;
                $("#projectModal").modal("show");
            } else {
                console.error("Failed to retrieve project details:", res.message);
            }
        },
        error: function (jqXHR, textStatus, errorThrown) {
            console.error("Get Project AJAX Error:", textStatus, errorThrown, jqXHR.responseText);
        }
    });
}

function deleteProject(event, projectId){
    event.preventDefault();
    if(confirm("Are you sure you want to delete this project?")) {
        $.ajax({
            url: "/taskflow/components/ProjectService.cfc?method=deleteProject",
            type: "POST",
            data: { projectID: projectId, csrfToken: $('#csrfToken').val() },
            dataType: "json",
            success: function(res) {
                if(res.status === "success") {
                    loadProjectsData();
                } else {
                    console.error("Failed to delete project:", res.message);
                }
            },
            error: function (jqXHR, textStatus, errorThrown) {
                console.error("Delete Project AJAX Error:", textStatus, errorThrown, jqXHR.responseText);
            }
        })
    }       
}

function renderProjectsCards(projects, containerId) {
    if (!$(containerId).length) {
        return;
    }

    if (!projects || projects.length === 0) {
        $(containerId).html('<div class="col-12 text-center text-muted">No projects found. Create one to get started!</div>');
        return;
    }

    let html = '';
    projects.forEach(project => {
        const projectName = escapeHtml(project.project_name);
        const projectDescription = escapeHtml(project.description);
        const projectStart = escapeHtml(project.start_date);
        const projectEnd = escapeHtml(project.due_date);
        const projectStatus = escapeHtml(project.project_status);
        const statusBadge = getStatusBadge(projectStatus);

        html += `
            <div class="col-12 col-md-6 col-lg-4 mb-4">
                <div class="card project-card h-100">
                    <div class="card-body" id="projectListId" onclick="onclickProjectCard(${project.project_id}, '${projectName}')">
                        <h5 class="card-title">${projectName}</h5>
                        <p class="card-text text-muted">${projectDescription}</p>
                        <div class="mb-2 fw-semibold">
                            <small>Start: ${projectStart}</small><br>
                            <small>End: ${projectEnd}</small>
                        </div>
                        <small class="mt-4">Status: ${statusBadge}</small>
                    </div>
                    <div class="card-footer bg-light d-flex gap-2 justify-content-end">
                        <button class="btn btn-sm btn-primary" onclick="editProject(event, ${project.project_id})"> 
                            <i class="fa-solid fa-pen-to-square"></i> Edit
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="deleteProject(event, ${project.project_id})"> 
                            <i class="fa-solid fa-trash"></i> Delete
                        </button>
                    </div>
                </div>
            </div>`;
    });
    $(containerId).html(html);
}

function onclickProjectCard(projectId, projectName){
    $.post("/taskflow/components/ProjectService.cfc?method=addProjectCount", { projectID: projectId, csrfToken: $('#csrfToken').val() });
    window.location.href = `/taskflow/tasks/taskView.cfm?project_id=${projectId}&project_name=${encodeURIComponent(projectName)}`;
}

// onclick="window.location.href = '/taskflow/tasks/taskView.cfm?project_id=${project.project_id}&project_name=${encodeURIComponent(project.project_name)}';"

// function getStatusBadge(status) {
//     const badges = {
//         'Pending': '<span class="status-badge bg-warn">Pending</span>',
//         'In Progress': '<span class="status-badge bg-inf">In Progress</span>',
//         'Completed': '<span class="status-badge bg-suc">Completed</span>'
//     };
//     return badges[status] || '<span class="badge bg-secondary">Unknown</span>';
// }

function loadProjectsData() {
    $.ajax({
        url: '/taskflow/components/ProjectService.cfc?method=getProjects',
        type: 'GET',
        dataType: 'json',
        success: function (res) {
            if (res.status === 'success') {
                let projectsList = res.projects;
                allProjects = projectsList || [];
                renderProjectsCards(allProjects, '#projectsList');
                renderProjectsCards(allProjects, '#projectsListFull');
            }
        },
        error: function () {
            console.error('Failed to load projects');
        }
    });
}

function resetProjectForm() {
    $('#projectForm')[0].reset();
    $('#projectId').val('');
    $('#projectName').removeClass('is-valid is-invalid');
    $('#projectDescription').removeClass('is-valid is-invalid');
    $('#projectStartDate').removeClass('is-valid is-invalid');
    $('#projectEndDate').removeClass('is-valid is-invalid');
    $('#projectStatus').removeClass('is-valid is-invalid');
    $('#projectFormError').addClass('d-none').text('');
    $('#projectForm').removeClass('was-validated');
    $('#projectModalLabel').text('Add Project');
    isEditMode = false;
    currentProjectId = null;
}

function getProjectFieldError(fieldName, value) {
    value = value ? value.trim() : '';

    switch(fieldName) {
        case 'projectName':
            if (!value) return 'Project name is required.';
            if (value.length < 3) return 'Project name must be at least 3 characters long.';
            if (value.length > 50) return 'Project name cannot exceed 50 characters.';
            return '';

        case 'projectDescription':
            if (!value) return 'Project description is required.';
            if (value.length < 10) return 'Description must be at least 10 characters long.';
            if (value.length > 500) return 'Description cannot exceed 500 characters.';
            return '';

        case 'projectStartDate':
            if (!value) return 'Start date is required.';
            return '';

        case 'projectEndDate':
            if (!value) return 'End date is required.';
            return '';

        case 'projectStatus':
            if (!value) return 'Project status is required.';
            return '';

        default:
            return '';
    }
}

function validateProjectForm() {
    const name = $('#projectName').val();
    const description = $('#projectDescription').val();
    const startDate = $('#projectStartDate').val();
    const endDate = $('#projectEndDate').val();
    const projectStatus = $('#projectStatus').val();

    let errors = [];
    let isValid = true;

    const nameError = getProjectFieldError('projectName', name);
    if (nameError) {
        errors.push(nameError);
        $('#projectName').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#projectName').addClass('is-valid').removeClass('is-invalid');
    }

    const descriptionError = getProjectFieldError('projectDescription', description);
    if (descriptionError) {
        errors.push(descriptionError);
        $('#projectDescription').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#projectDescription').addClass('is-valid').removeClass('is-invalid');
    }

    const startDateError = getProjectFieldError('projectStartDate', startDate);
    if (startDateError) {
        errors.push(startDateError);
        $('#projectStartDate').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#projectStartDate').addClass('is-valid').removeClass('is-invalid');
    }

    const endDateError = getProjectFieldError('projectEndDate', endDate);
    if (endDateError) {
        errors.push(endDateError);
        $('#projectEndDate').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#projectEndDate').addClass('is-valid').removeClass('is-invalid');
    }

    if (startDate && endDate && startDate > endDate) {
        errors.push('End date cannot be earlier than start date.');
        $('#projectEndDate').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    }

    const statusError = getProjectFieldError('projectStatus', projectStatus);
    if (statusError) {
        errors.push(statusError);
        $('#projectStatus').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#projectStatus').addClass('is-valid').removeClass('is-invalid');
    }

    if (!isValid) {
        const errorHtml = '<strong>Please fix :</strong><ul class="mb-0 mt-2">' +
            errors.map(e => `<li>${escapeHtml(e)}</li>`).join('') +
            '</ul>';
        $('#projectFormError').html(errorHtml).removeClass('d-none');
    } else {
        $('#projectFormError').addClass('d-none').text('');
    }

    return isValid;
}

function doughnutChart(canvas, chartData, chartTitle, totalCount, chartTitleMain) {

    const centerText = {
        id: 'centerText',

        afterDraw(chart) {

            const { ctx } = chart;
            const meta = chart.getDatasetMeta(0);
            if (!meta.data.length) return;

            const centerX = meta.data[0].x;
            const centerY = meta.data[0].y;

            ctx.save();

            ctx.font = 'bold 28px Arial';
            ctx.fillStyle = '#333';
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';

            ctx.fillText(totalCount, centerX, centerY - 10);

            ctx.font = '16px Arial';
            ctx.fillStyle = '#777';

            ctx.fillText(chartTitle, centerX, centerY + 20);
            ctx.restore();
        }
    };

    new Chart(canvas, {

        type: "doughnut",

        data: {

            labels: ["Pending", "In Progress", "Completed"],

            datasets: [{
                backgroundColor: [
                    "#ffa500",
                    "#0000ff",
                    "#008000"
                ],

                borderWidth: 0,

                data: chartData
            }]
        },

        options: {

            responsive: true,
            maintainAspectRatio: false,

            cutout: '70%',

            plugins: {

                legend: {
                    position: 'top',

                    labels: {
                        usePointStyle: true,
                        padding: 20
                    }
                },

                title: {
                    display: true,
                    text: chartTitleMain,

                    font: {
                        size: 18,
                        weight: 'bold'
                    },

                    padding: {
                        top: 10,
                        bottom: 15
                    }
                }
            }
        },

        plugins: [centerText]
    });
}

function getProjectStatusCounts() {
    const projectsChart = $('#projectsChart');
    const tasksChart = $('#tasksChart');
    
    $.ajax({
        url: '/taskflow/components/ProjectService.cfc?method=getProjectStatusCounts',
        type: 'GET',
        dataType: 'json',
        success: function(res){
            if (res.status === 'success'){
                doughnutChart(
                    projectsChart,
                    [res.projectCounts.pendingCount, res.projectCounts.inProgressCount, res.projectCounts.completedCount],
                    "Projects",
                    res.projectCounts.totalProjects,
                    "Projects by Status"
                );
                doughnutChart(
                    tasksChart,
                    [res.projectTasksCounts.pendingCount, res.projectTasksCounts.inProgressCount, res.projectTasksCounts.completedCount],
                    "Tasks",
                    res.projectTasksCounts.totalTasks,
                    "Tasks by Status"
                );
            }
            else{
                console.error('Failed to retrieve project status counts:', res.message);
            }
        },
        error: function() {
            console.error('Failed to load project status counts');
        }

    })


}




$(document).ready(function() {
    const projectModalEl = $("#projectModal");
    const projectModal = projectModalEl? new bootstrap.Modal(projectModalEl[0]): null;

    $("#addProjectBtnTop").click(function() {
        resetProjectForm();
    });
    
    if (projectModalEl.length) {
        projectModalEl.on('hidden.bs.modal', function () {
            resetProjectForm();
        });
    }

    loadProjectsData();
    getProjectStatusCounts();

    $('#projectName').on('keyup blur', function() {
        const error = getProjectFieldError('projectName', $(this).val());
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
    });

    $('#projectDescription').on('keyup blur', function() {
        const error = getProjectFieldError('projectDescription', $(this).val());
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
    });

    $('#projectStartDate').on('change blur', function() {
        const error = getProjectFieldError('projectStartDate', $(this).val());
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
    });

    $('#projectEndDate').on('change blur', function() {
        const error = getProjectFieldError('projectEndDate', $(this).val());
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
    });

    $('#projectStatus').on('change', function() {
        const error = getProjectFieldError('projectStatus', $(this).val());
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
    });
  
    $("#dashboardLink").click(function(e) {
        e.preventDefault();
        $("#pageTitle").text("Dashboard");
        $("#dashboardSection").show();
        $("#projectsSection").hide();
        $("#profileSection").hide();
        $(".nav-link").removeClass("active");
        $(this).addClass("active");
    });

    $("#projectListLink").click(function(e) {
        e.preventDefault();
        $("#pageTitle").text("All Projects");
        $("#dashboardSection").hide();
        $("#projectsSection").show();
        $("#profileSection").hide();
        $(".nav-link").removeClass("active");
        $(this).addClass("active");
        loadProjectsData();
    });

    $("#userProfileLink").click(function(e) {
        e.preventDefault();
        $("#pageTitle").text("User Profile");
        $("#dashboardSection").hide();
        $("#projectsSection").hide();
        $("#profileSection").show();
        $(".nav-link").removeClass("active");
        $(this).addClass("active");
    });


    $("#saveProjectBtn").click(function(e) {
        e.preventDefault();
        const submitBtn = $(this);
        submitBtn.prop("disabled", true);

        if (!validateProjectForm()) {
            submitBtn.prop("disabled", false);
            return;
        }

        const projectName = $("#projectName").val().trim();
        const description = $("#projectDescription").val().trim();
        const startDate = $("#projectStartDate").val().trim();
        const endDate = $("#projectEndDate").val().trim();
        const projectStatus = $("#projectStatus").val();
        const errorMsg = $("#projectFormError");
        errorMsg.addClass("d-none").text("");

        const method = isEditMode ? 'updateProjectDetails' : 'addProject';
        const data = {
            ProjectName: projectName,
            Description: description,
            StartDate: startDate,
            DueDate: endDate,
            ProjectStatus: projectStatus,
            csrfToken: $('#csrfToken').val()
        };

        if (isEditMode) {
            data.projectID = currentProjectId;
        }
        
        $.ajax({
            url:`/taskflow/components/ProjectService.cfc?method=${method}`,
            type:"POST",
            data: data,
            dataType: "json",

            success: function(res) {
                submitBtn.prop("disabled", false);
                if(res.status === "success") {
                    if (projectModal) {
                        projectModal.hide();
                    }
                    resetProjectForm();
                    loadProjectsData();
                } else {
                    errorMsg.removeClass("d-none").text(res.message);
                }
            },
            error: function(XHR, status, error) {
                submitBtn.prop("disabled", false);
                console.error("Add Project AJAX Error:", status, error, XHR.responseText);
                errorMsg.removeClass("d-none").text("Something went wrong. Please try again.");
            }

        })
    })

});