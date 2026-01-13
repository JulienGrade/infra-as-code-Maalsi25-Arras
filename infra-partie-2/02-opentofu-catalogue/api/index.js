import express from "express";

const app = express();
const port = process.env.PORT || 3000;

app.get("/", (req, res) => {
    res.json({
        status: "ok",
        message: "Catalogue API",
        postgres: {
            host: process.env.PGHOST,
            db: process.env.PGDATABASE,
            user: process.env.PGUSER
        },
        redis: {
            host: process.env.REDIS_HOST
        }
    });
});

app.listen(port, () => {
    console.log(`API catalogue démarrée sur le port ${port}`);
});
