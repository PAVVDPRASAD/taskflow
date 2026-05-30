let currentTaskId = null;
let editingTaskId = null;
currentProjectId = null;

function loadTasks(projectId) {
        const container = $('#tasksContainer');
        container.empty();
        container.html('<div class="col-12 text-center"><div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div></div>');
        $.ajax({
        url: "/taskflow/components/TaskService.cfc?method=getTaskModules",
        type: 'GET',
        dataType: 'json',
        data: {
            projectId: projectId,
            csrfToken: $('#csrfToken').val()
        },

        success: function (response) {
            const container = $('#tasksContainer');
            let taskList = response.data || [];

            if (taskList.length === 0) {
                container.html('<div class="col-12 text-center text-muted">No tasks found for this project.</div>');
                return;
            }

            const tasksHtml = taskList.map(task => {
                const taskId = task.TASK_ID;
                const title = task.TITLE;
                const description = task.TASK_DESCRIPTION;
                const status =  task.STATUS;
                const dueDate = task.DUE_DATE;
                const filepath = task.FILE_PATH;
                
                let formattedDate = 'No Due Date';
                if (dueDate) {
                    const dateObj = new Date(dueDate);
                    if (!isNaN(dateObj.getTime())) {
                        formattedDate = dateObj.toLocaleDateString();
                    }
                }
                
                let fileHtml = "";

                if (task.FILE_PATH) {
                    const fileUrl = `/taskflow/uploads/${task.FILE_PATH}`;
                    const ext = task.FILE_PATH.split('.').pop().toLowerCase();

                    if (ext === 'pdf') {
                        fileHtml = `<iframe src="${fileUrl}" width="100%" height="300"></iframe>`;
                    }
                    else if (['png', 'jpg', 'jpeg'].includes(ext)) {
                        fileHtml = `<img src="${fileUrl}" class="img-fluid mb-2">`;
                    }
                    else {
                        fileHtml = `<a href="${fileUrl}" target="_blank">Download File</a>`;
                    }

                } else {
                    fileHtml = `<span class="text-muted">No file attached</span>`;
                }

                return `
                    <div class="col-12 col-md-6 col-lg-4 mb-3">
                        <div class="card h-100 shadow-lg border-0">
                            <div class="card-body d-flex flex-column">
                                ${fileHtml}
                                <h5 class="card-title">${escapeHtml(title)}</h5>
                                <p class="card-text text-muted">${escapeHtml(description)}</p>
                                <div class="gap-4 mt-auto d-flex justify-content-between align-items-center">
                                    <small class="">Due: ${formattedDate}</small>
                                    <small>${getStatusBadge(escapeHtml(status))}</small>
                                </div>
                            </div>
                            
                            <div class="card-footer bg-transparent border-0 d-flex justify-content-end gap-2">
                                <button class="btn btn-sm btn-outline-primary me-2 edit-task-btn" data-task-id="${taskId}">
                                    <i class="fa-solid fa-pen-to-square"></i> Edit
                                </button>
                                <button class="btn btn-sm btn-danger delete-task-btn" data-task-id="${taskId}">
                                    <i class="fa-solid fa-trash"></i> Delete
                                </button>
                            </div>
                        </div>
                    </div>`;
            }).join('');
            container.html(tasksHtml);
        },

        error: function (xhr, status, error) {
            console.error("Load tasks error:", status, error);
            console.error("Server Response:", xhr.responseText);
            
            let errorMsg = "Failed to load tasks. Please try again.";
            const container = $('#tasksContainer');
            container.html(`<div class="col-12 text-center text-danger">${escapeHtml(errorMsg)}<br><small>Check browser console for details.</small></div>`);
        }
    });
}

function deleteTask(taskId) {
    if (!confirm("Are you sure you want to delete this task?")) {
        return;
    }
    $.ajax({
        url: "/taskflow/components/TaskService.cfc?method=deleteTask",
        type: "POST",
        data: { 
            taskId: taskId, 
            projectId: currentProjectId,
            csrfToken: $('#csrfToken').val()
        },
        dataType: "json",
        success: function (res) {
            if (res.status === "success") {
                loadTasks(currentProjectId);
            } else {
                alert("Error deleting task: " + res.message);
            }
        },
        error: function (xhr, status, error) {
            console.error("Error deleting task:", error);
            console.error("Response:", xhr.responseText);
            alert("Error deleting task. Please try again.");
        }
    });
}

function editTask(taskId) {
    editingTaskId = taskId;
    
    $.ajax({
        url: "/taskflow/components/TaskService.cfc?method=getTaskById",
        type: "GET",
        data: { taskId: taskId, projectId: currentProjectId },
        data: {
            taskId: taskId,
            projectId: currentProjectId,
            csrfToken: $('#csrfToken').val()
        },
        dataType: "json",
        success: function (res) {
            if (res.status === "success") {
                let task = res.data;
                
                $('#taskId').val(task.task_id);
                $('#taskName').val(task.title).addClass('is-valid').removeClass('is-invalid');
                $('#taskDescription').val(task.task_description).addClass('is-valid').removeClass('is-invalid');
                $('#taskEndDate').val(task.due_date).addClass('is-valid').removeClass('is-invalid');
                $('#taskStatus').val(task.status).addClass('is-valid').removeClass('is-invalid');
                $('#taskFormError').addClass('d-none').html('');
                
                $('#addTaskModalLabel').text('Edit Task');
                $('#saveTaskBtn').html('<i class="fa-solid fa-pen"></i> Update Task').removeClass('btn-primary').addClass('btn-success');
                
                const modal = new bootstrap.Modal(document.getElementById('addTaskModal'));
                modal.show();
            } else {
                alert("Error loading task: " + (res.message || "Unknown error occurred"));
            }
        },
        error: function (xhr, status, error) {
            console.error("Error fetching task:", error);
            alert("Error loading task. Please try again.");
        }
    });
}

function resetTaskForm() {
    $('#taskForm')[0].reset();
    $('#taskId').val('');
    $('#taskName').removeClass('is-valid is-invalid');
    $('#taskDescription').removeClass('is-valid is-invalid');
    $('#taskEndDate').removeClass('is-valid is-invalid');
    $('#taskStatus').removeClass('is-valid is-invalid');
    $('#taskFile').removeClass('is-valid is-invalid');
    $('#taskFormError').addClass('d-none').html('');
    $('#taskForm').removeClass('was-validated');
    $('#addTaskModalLabel').text('Add Task');
    $('#saveTaskBtn').html('<i class="fa-solid fa-floppy-disk"></i> Save Task').removeClass('btn-success').addClass('btn-primary');
    editingTaskId = null;
}

function getFieldError(fieldName, value) {
    value = value ? value.trim() : '';
    
    switch(fieldName) {
        case 'taskName':
            if (!value) return 'Task name is required.';
            if (value.length < 3) return 'Task name must be at least 3 characters long.';
            if (value.length > 50) return 'Task name cannot exceed 50 characters.';
            return '';
            
        case 'taskDescription':
            if (!value) return 'Description is required.';
            if (value.length < 10) return 'Description must be at least 10 characters long.';
            if (value.length > 500) return 'Description cannot exceed 500 characters.';
            return '';
            
        case 'taskEndDate':
            if (!value) return 'Due date is required.';
            return '';
            
        case 'taskStatus':
            if (!value) return 'Status is required. Please select a status.';
            return '';
            
        default:
            return '';
    }
}

function validateTaskForm() {
    const taskName = $('#taskName').val();
    const taskDescription = $('#taskDescription').val();
    const dueDate = $('#taskEndDate').val();
    const taskStatus = $('#taskStatus').val();
    
    let errors = [];
    let isValid = true;
    
    const nameError = getFieldError('taskName', taskName);
    if (nameError) {
        errors.push(nameError);
        $('#taskName').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#taskName').addClass('is-valid').removeClass('is-invalid');
    }
    
    const descError = getFieldError('taskDescription', taskDescription);
    if (descError) {
        errors.push(descError);
        $('#taskDescription').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#taskDescription').addClass('is-valid').removeClass('is-invalid');
    }
    
    const dateError = getFieldError('taskEndDate', dueDate);
    if (dateError) {
        errors.push(dateError);
        $('#taskEndDate').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#taskEndDate').addClass('is-valid').removeClass('is-invalid');
    }
    
    const statusError = getFieldError('taskStatus', taskStatus);
    if (statusError) {
        errors.push(statusError);
        $('#taskStatus').addClass('is-invalid').removeClass('is-valid');
        isValid = false;
    } else {
        $('#taskStatus').addClass('is-valid').removeClass('is-invalid');
    }
    
    if (!isValid) {
        const errorHtml = '<strong>Please fix:</strong><ul class="mb-0 mt-2">' + 
                         errors.map(e => `<li>${escapeHtml(e)}</li>`).join('') + 
                         '</ul>';
        $('#taskFormError').html(errorHtml).removeClass('d-none');
    } else {
        $('#taskFormError').addClass('d-none').html('');
    }
    
    return isValid;
}

$(document).ready(function () {
    const params = new URLSearchParams(window.location.search);
    let projectId = params.get("project_id");
    currentProjectId = projectId;

    if (projectId) {
        loadTasks(currentProjectId);
    }

    $('#addTaskBtn').on('click', function() {
        resetTaskForm();
    });

    $('#taskName').on('keyup blur', function() {
        const value = $(this).val();
        const error = getFieldError('taskName', value);
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
        $('#taskNameCounter').text(value.length);
    });

    $('#taskDescription').on('keyup blur', function() {
        const value = $(this).val();
        const error = getFieldError('taskDescription', value);
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
        $('#descriptionCounter').text(value.length);
    });

    $('#taskEndDate').on('change blur', function() {
        const error = getFieldError('taskEndDate', $(this).val());
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
    });

    $('#taskStatus').on('change', function() {
        const error = getFieldError('taskStatus', $(this).val());
        $(this).toggleClass('is-invalid', !!error).toggleClass('is-valid', !error);
    });

    $('#addTaskModal').on('hidden.bs.modal', function() {
        resetTaskForm();
    });

    $('#saveTaskBtn').click(function () {
        if (!validateTaskForm()) {
            return;
        }

        const formData = new FormData($("#taskForm")[0]);
        formData.set("projectId", projectId);
        formData.set("csrfToken", $('#csrfToken').val());
        
        if (editingTaskId) {
            formData.set("taskId", editingTaskId);
        }
        
        const url = editingTaskId ? "/taskflow/components/TaskService.cfc?method=updateTask" : "/taskflow/components/TaskService.cfc?method=addTask";
       
        $('#saveTaskBtn').prop('disabled', true);

        $.ajax({
            url: url,
            type: "POST",
            data: formData,
            processData: false,
            contentType: false,
            dataType: "json",
            success: function (res) {
                if (res.status === "success") {
                    $('#taskFormError')
                        .removeClass('d-none alert-danger')
                        .addClass('alert-success')
                        .html('<i class="fa-solid fa-circle-check"></i> Task saved successfully.');

                    setTimeout(function() {
                        $('#addTaskModal .btn-close').click();
                        resetTaskForm();
                        loadTasks(currentProjectId);
                        $('#saveTaskBtn').prop('disabled', false);
                    }, 800);

                } else {
                    $('#taskFormError')
                        .removeClass('d-none alert-success')
                        .addClass('alert-danger')
                        .html('<i class="fa-solid fa-circle-exclamation"></i> <strong>Error:</strong> ' + escapeHtml(res.message || 'Failed to save task.'));
                    $('#saveTaskBtn').prop('disabled', false);
                }
            },
            error: function (xhr) {
                let errorMsg = 'Error saving task. Please try again.';
                console.error(errorMsg);
                $('#taskFormError')
                    .removeClass('d-none alert-success')
                    .addClass('alert-danger')
                    .html('<i class="fa-solid fa-circle-exclamation"></i> <strong>Error:</strong> ' + escapeHtml(errorMsg));
                $('#saveTaskBtn').prop('disabled', false);
            }
        });
    });

    $('#tasksContainer').on('click', '.delete-task-btn', function(event) {
        event.preventDefault();
        deleteTask($(this).data('task-id'));
    });

    $('#tasksContainer').on('click', '.edit-task-btn', function(event) {
        event.preventDefault();
        editTask($(this).data('task-id'));
    });
});
