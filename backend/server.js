const Joi = require('joi');
const express = require('express');
const multer = require('multer');
const { db } = require('./lib/firebase.js');
const { supabase } = require('./lib/supabase.js');

const app = express();
const port = process.env.PORT || 3000;

const upload = multer({ storage: multer.memoryStorage() });

app.use(express.json());

app.get('/tasks', async (req, res) => {
    const taskRef = db.collection('tasks');

    try {
        const snapshot = await taskRef.get();
        const tasks = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.status(200).json(tasks);
    } catch (err) {
        console.log("Error: ", err);
        res.status(500).send("Unable to fetch tasks :(");
    }
});

app.post('/task', async (req, res) => {
    const taskSchema = Joi.object({
        title: Joi.string().min(3).required(),
        description: Joi.string().min(10).required(),
    });

    const { error } = taskSchema.validate(req.body);
    if (error) return res.status(400).send(error.details[0].message);

    const taskRef = db.collection('tasks').doc();
    const taskBody = {
        title: req.body.title,
        description: req.body.description,
        created_at: Date.now()
    }

    try {
        const taskRes = await taskRef.set(taskBody);
        res.status(201).json({
            id: taskRef.id,
            ...taskBody
        });
    } catch (err) {
        console.log("Database error:", err);
        res.status(500).send("Failed to save the task");
    }
});

app.post('/submission', upload.single("file"), async (req, res) => {
    const taskSchema = Joi.object({
        task_id: Joi.string().min(3).required(),
    });

    const { error } = taskSchema.validate(req.body);
    if (error) return res.status(400).send(error.details[0].message);

    const submissionRef = db.collection('submissions').doc();

    try {
        const { file } = req;
        if (!file) {
            return res.status(400).send("No file uploaded.");
        }
        if (!file.mimetype.startsWith("image") &&
            !file.mimetype.startsWith("video") &&
            !file.mimetype.startsWith("audio")) {
        return res.status(400).send("Invalid file type");
        }

        const filePath = `${Date.now()}-${file.originalname}`;
        const { data: uploadData, error: uploadError } = await supabase.storage
            .from("task-uploads")
            .upload(filePath, file.buffer, {
                contentType: file.mimetype
        });

        if (uploadError) throw uploadError;

        const { data: publicUrlData } = supabase.storage.from("task-uploads").getPublicUrl(uploadData.path);

        const submissionBody = {
            task_id: req.body.task_id,
            file_url: publicUrlData.publicUrl,
            created_at: Date.now()
        }
        const submissionRes = await submissionRef.set(submissionBody);
        res.status(201).json({
            id: submissionRef.id,
            ...submissionBody
        });
    } catch (err) {
        console.log("Database error:", err);
        res.status(500).send("Failed to save the task");
    }
});

app.listen(port, () => console.log(`Server listening on port ${port}`));
