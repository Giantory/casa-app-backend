import mysql from 'mysql';
import { config } from 'dotenv';
config();

const dbConfig = {
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
};

const db = mysql.createConnection(dbConfig);

// connection to database
// async () => {
//     try {
//         const connection = db.connect() 
//         console.info(`Database Connected`);
//         return connection;
//     } catch (error) {
//         console.error(`Database connection error: ${error}`);
//     }
// };

export default db;