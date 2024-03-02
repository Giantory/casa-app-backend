import { Router } from 'express';

//to upload files
import multer from 'multer';
import path from 'path';

//controllers
import { getAllConsums, processConsum, processManyConsums } from './consum.controller.js';

const storage = multer.diskStorage({
    destination: "./public/uploads/files",
    filename: function (req, file, cb) {
        cb(
            null,
            file.originalname + "-" + Date.now() + path.extname(file.originalname)
        );
    },
});
const upload = multer({ storage: storage });


const router = new Router();

router.get(`/api/consums`, getAllConsums);
router.post(`/api/consums/processConsum`, processConsum);
router.post(`/api/consums/processManyConsums`, upload.single("file"), processManyConsums);

export default router;