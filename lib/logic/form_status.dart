/// Status shared by one-shot actions (submit a form, update a status).
enum FormStatus { idle, submitting, success, failure }

/// Status shared by stream-backed lists and details.
enum LoadStatus { loading, loaded, failure }
