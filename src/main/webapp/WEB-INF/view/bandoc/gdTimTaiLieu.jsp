<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Tìm tài liệu"/>
<c:set var="catalogView" value="${true}"/>
<c:set var="pageStylesheet" value="/assets/css/gdTimTaiLieu.css"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<p class="search-description">Tra cứu sách, giáo trình và các tài liệu trong thư viện.</p>
<form class="search-form" method="get" action="<c:url value='/documents'/>" role="search">
    <div class="search-fields">
        <select name="field" aria-label="Tìm theo">
            <option value="all" ${field eq 'all' ? 'selected' : ''}>Mọi trường</option>
            <option value="title" ${field eq 'title' ? 'selected' : ''}>Tên tài liệu</option>
            <option value="author" ${field eq 'author' ? 'selected' : ''}>Tác giả</option>
            <option value="code" ${field eq 'code' ? 'selected' : ''}>Mã tài liệu</option>
            <option value="isbn" ${field eq 'isbn' ? 'selected' : ''}>ISBN / ISSN</option>
        </select>
        <input name="keyword" aria-label="Từ khóa" maxlength="500"
               placeholder="Nhập từ khóa"
               value="<c:out value="${keyword}"/>">
    </div>
    <div class="search-filters" role="group" aria-label="Bộ lọc tìm kiếm">
        <label class="field">Loại tài liệu
            <select name="type">
                <option value="">Tất cả</option>
                <c:forEach var="option" items="${typeLabels}">
                    <option value="${option.key}" ${type eq option.key ? 'selected' : ''}>
                        <c:out value="${option.value}"/>
                    </option>
                </c:forEach>
            </select>
        </label>
        <label class="field">Năm xuất bản
            <input name="year" inputmode="numeric" pattern="[1-9][0-9]{3}" maxlength="4"
                   value="<c:out value="${year}"/>">
        </label>
        <c:url var="clearUrl" value="/documents">
            <c:param name="field" value="${field}"/>
            <c:param name="keyword" value="${keyword}"/>
        </c:url>
        <c:if test="${not empty type or not empty year}">
            <a class="action" href="<c:out value="${clearUrl}"/>">Bỏ bộ lọc</a>
        </c:if>
        <button type="submit">Tìm kiếm</button>
    </div>
</form>
<c:if test="${documents eq null and empty error}">
    <p class="search-hint">Nhập từ khóa hoặc chọn bộ lọc để tìm tài liệu.</p>
</c:if>
<c:if test="${not empty error}">
    <p class="notice error" role="alert"><c:out value="${error}"/></p>
</c:if>
<c:choose>
    <c:when test="${not empty documents}">
        <section class="results-panel" aria-labelledby="catalog-result-heading">
            <header class="results-header">
                <h2 id="catalog-result-heading">Kết quả tìm kiếm</h2>
                <span>${documents.size()} tài liệu</span>
            </header>
            <ul class="document-list">
                <c:forEach var="doc" items="${documents}">
                    <c:url var="detailUrl" value="/documents/detail">
                        <c:param name="documentId" value="${doc.id}"/>
                        <c:param name="keyword" value="${keyword}"/>
                        <c:param name="field" value="${field}"/>
                        <c:param name="type" value="${type}"/>
                        <c:param name="year" value="${year}"/>
                    </c:url>
                    <li class="document-card">
                        <div>
                            <h3><a href="<c:out value="${detailUrl}"/>"><c:out value="${doc.title}"/></a></h3>
                            <p class="document-meta">
                                <c:out value="${typeLabels[doc.documentType]}"/>
                                <c:if test="${not empty doc.author}"> · <c:out value="${doc.author}"/></c:if>
                                <c:if test="${not empty doc.publicationYear}"> · <c:out value="${doc.publicationYear}"/></c:if>
                                · <c:out value="${doc.documentCode}"/>
                            </p>
                            <div class="catalog-availability">
                                <span class="catalog-status ${doc.borrowable ? 'catalog-status-ready' : ''}">
                                    <c:choose>
                                        <c:when test="${doc.borrowable}">Cho mượn về</c:when>
                                        <c:otherwise>Chỉ đọc tại thư viện</c:otherwise>
                                    </c:choose>
                                </span>
                            </div>
                        </div>
                        <a class="detail-link"
                           href="<c:out value="${detailUrl}"/>"
                           aria-label="Xem chi tiết <c:out value="${doc.title}"/>">
                            Xem chi tiết <span aria-hidden="true">→</span>
                        </a>
                    </li>
                </c:forEach>
            </ul>
        </section>
    </c:when>
    <c:when test="${documents ne null}">
        <p class="notice">Không tìm thấy tài liệu phù hợp với tiêu chí đã chọn.</p>
    </c:when>
</c:choose>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
