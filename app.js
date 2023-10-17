import express from 'express';

//router routes
import driverRoutes from './entities/driver/driver.routes.js';
import vehicleRoutes from './entities/vehicle/vehicle.routes.js';
const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(driverRoutes);
app.use(vehicleRoutes);

export default app;
