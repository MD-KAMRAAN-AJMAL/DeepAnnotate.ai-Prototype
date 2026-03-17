import { initializeApp } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-app.js";
import { getFirestore, collection, query, orderBy, onSnapshot } from "https://www.gstatic.com/firebasejs/10.8.0/firebase-firestore.js";

const firebaseConfig = {
    projectId: "deepannotate-ai-prototype",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

let tasksMap = {};
let latestSubmissions = [];

const API_BASE_URL = 'http://localhost:4300';

window.showPage = (pageId) => {
    document.querySelectorAll('.page').forEach(p => p.style.display = 'none');
    document.getElementById(pageId).style.display = 'block';

    document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
    event.currentTarget.classList.add('active');
};

const taskForm = document.getElementById('task-form');
taskForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const submitBtn = taskForm.querySelector('.submit-btn');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Creating...';

    const formData = new FormData(taskForm);
    const data = {
        title: formData.get('title'),
        description: formData.get('description'),
        task_type: formData.get('task_type')
    };

    try {
        const response = await fetch(`${API_BASE_URL}/task`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });

        if (response.ok) {
            alert('Task created successfully!');
            taskForm.reset();
        } else {
            const error = await response.text();
            alert(`Error: ${error}`);
        }
    } catch (err) {
        console.error(err);
        alert('Failed to connect to backend. Make sure it is running on port 4300.');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Create Task';
    }
});

const tasksQuery = collection(db, "tasks");
onSnapshot(tasksQuery, (snapshot) => {
    snapshot.forEach((doc) => {
        tasksMap[doc.id] = doc.data().title;
    });
    if (latestSubmissions.length > 0) {
        renderSubmissions(latestSubmissions);
    }
});

function renderSubmissions(submissions) {
    const submissionsList = document.getElementById('submissions-list');
    if (submissions.length === 0) {
        submissionsList.innerHTML = '<tr class="empty-state"><td colspan="3">No submissions yet.</td></tr>';
        return;
    }

    submissionsList.innerHTML = '';
    submissions.forEach((data) => {
        const date = new Date(data.created_at).toLocaleString();
        const taskDisplay = tasksMap[data.task_id] || data.task_id || 'N/A';

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${taskDisplay}</td>
            <td><a href="${data.file_url}" target="_blank" class="file-link">View File</a></td>
            <td>${date}</td>
        `;
        submissionsList.appendChild(tr);
    });
}

const q = query(collection(db, "submissions"), orderBy("created_at", "desc"));

onSnapshot(q, (snapshot) => {
    latestSubmissions = snapshot.docs.map(doc => doc.data());
    renderSubmissions(latestSubmissions);
}, (error) => {
    console.error("Firestore listener failed:", error);
    const submissionsList = document.getElementById('submissions-list');
    submissionsList.innerHTML = '<tr class="empty-state"><td colspan="3" style="color: red;">Failed to load submissions. Check Firebase config/permissions.</td></tr>';
});
