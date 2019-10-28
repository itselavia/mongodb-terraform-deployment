sleep(15000);

rs.initiate( {
    _id : "cmpe281",
    members: [
       { _id: 0, host: "primary:27017", priority: 1000 },
       { _id: 1, host: "secondary1:27017", priority: 0.5 },
       { _id: 2, host: "secondary2:27017", priority: 0.5 }
    ]
 })

sleep(15000);