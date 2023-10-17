import express from 'express';

//router routes
import driverRoutes from './entities/driver/driver.routes.js';
import vehicleRoutes from './entities/vehicle/vehicle.routes.js';
import consumRoutes from './entities/consum/consum.routes.js';
import dispatchRoutes from './entities/dispatch/dispatch.routes.js';
const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use(driverRoutes);
app.use(vehicleRoutes);
app.use(consumRoutes);
app.use(dispatchRoutes);

export default app;
