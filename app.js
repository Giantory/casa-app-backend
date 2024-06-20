import express from 'express';
import cors from 'cors';

//router routes
import driverRoutes from './entities/driver/driver.routes.js';
import vehicleRoutes from './entities/vehicle/vehicle.routes.js';
import consumRoutes from './entities/consum/consum.routes.js';
import dispatchRoutes from './entities/dispatch/dispatch.routes.js';
import analyticRoutes from './entities/analytic/analytic.routes.js';


const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors({
    origin: '*'
}));

app.use(driverRoutes);
app.use(vehicleRoutes);
app.use(consumRoutes);
app.use(dispatchRoutes);
app.use(analyticRoutes);

export default app;
