import { Router } from 'express';

//controllers
import { getAllBrands, getBrandById } from './brand.controller.js';

const router = new Router();

router.get(`/api/brands`, getAllBrands);
router.get(`/api/brands/:id/`, getBrandById);


export default router;