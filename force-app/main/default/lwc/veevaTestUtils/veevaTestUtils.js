const clearUp = () => {
    const body = document.body;
    while (body.firstChild) {
        body.removeChild(body.firstChild);
    }
    jest.clearAllMocks();
}

const getElement = (from, path) => {
    let result = from;
    path.split(' ').every(x => {
        let pair = x.split(':');
        let saved = result;
        result = (result.shadowRoot || result).querySelectorAll(pair[0])[pair[1] || 0];
        if (result == null) {
            result = saved.querySelectorAll(pair[0])[pair[1] || 0];
        }
        return result ? true : false; // break out of loop if false
    });
    return result;
}

const flushPromises = () => {
    // eslint-disable-next-line no-undef
    return new Promise(resolve => setImmediate(resolve));
}
export { clearUp, getElement, flushPromises };