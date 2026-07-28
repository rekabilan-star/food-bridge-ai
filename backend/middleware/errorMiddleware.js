const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  console.log(err);

  if (err.name === 'CastError') {
    const message = `Resource not found with id of ${err.value}`;
    error = new Error(message);
    res.status(404);
  }

  if (err.code === 11000) {
    const message = 'Duplicate field value entered';
    error = new Error(message);
    res.status(400);
  }

  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map((val) => val.message);
    error = new Error(message);
    res.status(400);
  }

  res.status(res.statusCode === 200 ? 500 : res.statusCode).json({
    success: false,
    message: error.message || 'Server Error',
    error: error.errors || {},
  });
};

module.exports = errorHandler;
