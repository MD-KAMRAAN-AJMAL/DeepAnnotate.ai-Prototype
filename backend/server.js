const Joi = require('joi');
const express = require('express');
const multer = require('multer');
const db = require('./lib/mysql.js');
const cors = require('cors');
const { v1: uuidv1 } = require('uuid');
const { s3, PutObjectCommand } = require('./lib/s3.js');

const app = express();
const port = process.env.PORT || 3000;

const upload = multer({ storage: multer.memoryStorage() });

app.use(cors());
app.use(express.json());

app.get('/tasks', async (req, res) => {
    try {
        const [rows] = await db.execute('SELECT * FROM tasks');
        res.status(200).json(rows);
    } catch (err) {
        console.error(err);
        res.status(500).send("Unable to fetch tasks");
    }
});

app.post('/task', async (req, res) => {
    const schema = Joi.object({
        title: Joi.string().min(3).required(),
        description: Joi.string().min(10).required(),
        task_type: Joi.string().valid('video', 'audio', 'image').required(),
        task_difficulty: Joi.string().valid('easy', 'difficult').required(),
    });

    const { error } = schema.validate(req.body);
    if (error) return res.status(400).send(error.details[0].message);

    const id = uuidv1();

    try {
        await db.execute(
            'INSERT INTO tasks (id, title, description, task_type, task_difficulty) VALUES (?, ?, ?, ?, ?)',
            [id, req.body.title, req.body.description, req.body.task_type, req.body.task_difficulty]
        );

        res.status(201).json({
            id,
            ...req.body
        });
    } catch (err) {
        console.error(err);
        res.status(500).send("Failed to save task");
    }
});

app.post('/submission', upload.single("file"), async (req, res) => {
    const schema = Joi.object({
        task_id: Joi.string().required(),
    });

    const { error } = schema.validate(req.body);
    if (error) return res.status(400).send(error.details[0].message);

    try {
        const { file } = req;

        if (!file) return res.status(400).send("No file uploaded.");

        if (!file.mimetype.startsWith("image") &&
            !file.mimetype.startsWith("video") &&
            !file.mimetype.startsWith("audio")) {
            return res.status(400).send("Invalid file type");
        }

        const fileKey = `${Date.now()}-${file.originalname}`;

        await s3.send(new PutObjectCommand({
            Bucket: process.env.AWS_BUCKET_NAME,
            Key: fileKey,
            Body: file.buffer,
            ContentType: file.mimetype
        }));

        const fileUrl = `https://${process.env.AWS_BUCKET_NAME}.s3.${process.env.AWS_REGION}.amazonaws.com/${fileKey}`;

        const id = uuidv1();

        await db.execute(
            'INSERT INTO submissions (id, task_id, file_url) VALUES (?, ?, ?)',
            [id, req.body.task_id, fileUrl]
        );

        res.status(201).json({
            id,
            task_id: req.body.task_id,
            file_url: fileUrl
        });

    } catch (err) {
        console.error(err);
        res.status(500).send("Failed to save submission");
    }
});

app.get('/submissions', async (req, res) => {
    try {
        const [rows] = await db.execute(`
            SELECT s.*, t.title as task_title 
            FROM submissions s 
            LEFT JOIN tasks t ON s.task_id = t.id
            ORDER BY s.id DESC
        `);
        res.status(200).json(rows);
    } catch (err) {
        console.error(err);
        res.status(500).send("Unable to fetch submissions");
    }
});

app.listen(port, () => console.log(`Server running on ${port}`));
