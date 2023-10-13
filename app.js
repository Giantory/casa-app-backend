import express from 'express';

//router routes
import driverRoutes from './entities/driver/driver.routes.js';

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(driverRoutes);

export default app;
