
db = db.getSiblingDB('admin');

db.createUser( {
    user: "admin",
    pwd: "cmpe281",
    roles: [{ role: "root", db: "admin" }]
});