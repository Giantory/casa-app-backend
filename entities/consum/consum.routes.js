import { Router } from 'express';

//to upload files
import multer from 'multer';
import path from 'path';

//controllers
import { getAllConsums, getConsumoByDispatchId, processConsum, processManyConsums, createConsum } from './consum.controller.js';

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
router.get(`/api/consums/:id/`, getConsumoByDispatchId);
router.post(`/api/consums/processConsum`, processConsum);
router.post(`/api/consums/processManyConsums`, upload.single("file"), processManyConsums);
router.post(`/api/consums/createConsum`, createConsum);

export default router;