<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Chi tiết tài liệu"/>
<c:set var="catalogView" value="${true}"/>
<c:set var="pageStylesheet" value="/assets/css/gdChiTietTaiLieu.css"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<c:url var="searchUrl" value="/documents">
    <c:param name="keyword" value="${keyword}"/>
    <c:param name="field" value="${field}"/>
    <c:param name="type" value="${type}"/>
    <c:param name="year" value="${year}"/>
</c:url>
<a class="back" href="<c:out value="${searchUrl}"/>">← Quay về tìm tài liệu</a>
<c:if test="${not empty error}"><p class="notice error" role="alert"><c:out value="${error}"/></p></c:if>
<c:if test="${not empty document}">
    <p class="record-code"><c:out value="${document.documentCode}"/></p>
    <h2 class="module-subtitle"><c:out value="${document.title}"/></h2>
    <section class="panel metadata" aria-labelledby="document-metadata">
        <h2 id="document-metadata">Thông tin tài liệu</h2>
        <dl class="details">
            <div>
                <dt>Loại tài liệu</dt>
                <dd><c:out value="${typeLabels[document.documentType]}" default="—"/></dd>
            </div>
            <c:if test="${not empty document.author}">
                <div>
                    <dt>Tác giả</dt>
                    <dd><c:out value="${document.author}"/></dd>
                </div>
            </c:if>
            <c:if test="${not empty document.publisher}">
                <div>
                    <dt>Nhà xuất bản</dt>
                    <dd><c:out value="${document.publisher}"/></dd>
                </div>
            </c:if>
            <c:if test="${not empty document.publicationYear}">
                <div>
                    <dt>Năm xuất bản</dt>
                    <dd><c:out value="${document.publicationYear}"/></dd>
                </div>
            </c:if>
            <c:if test="${not empty document.isbnOrIssn}">
                <div>
                    <dt>ISBN / ISSN</dt>
                    <dd><c:out value="${document.isbnOrIssn}"/></dd>
                </div>
            </c:if>
            <c:if test="${not empty document.subjectClassification}">
                <div>
                    <dt>Phân loại chủ đề</dt>
                    <dd><c:out value="${document.subjectClassification}"/></dd>
                </div>
            </c:if>
            <c:if test="${not empty document.edition}">
                <div>
                    <dt>Ấn bản</dt>
                    <dd><c:out value="${document.edition}"/></dd>
                </div>
            </c:if>
            <div class="full">
                <dt>Mô tả</dt>
                <dd><c:out value="${empty document.description ? 'Chưa có mô tả cho tài liệu này.' : document.description}"/></dd>
            </div>
        </dl>
    </section>
    <div class="page-heading section-heading">
        <h2>Các bản tài liệu</h2>
        <div class="catalog-availability">
            <span class="catalog-status ${document.borrowable ? 'catalog-status-ready' : ''}">
                <c:choose>
                    <c:when test="${document.borrowable}">Cho mượn về</c:when>
                    <c:otherwise>Chỉ đọc tại thư viện</c:otherwise>
                </c:choose>
            </span>
            <c:set var="totalCount" value="${items.size()}"/>
            <div class="availability-count">
                <strong><c:out value="${availableCount}"/>/<c:out value="${totalCount}"/> bản sẵn có</strong>
            </div>
        </div>
    </div>
    <c:choose>
        <c:when test="${empty items}"><p class="notice">Đầu tài liệu này chưa có bản vật lý.</p></c:when>
        <c:otherwise>
            <div class="table-scroll" tabindex="0" role="region" aria-label="Các bản tài liệu">
                <table>
                    <thead>
                        <tr>
                            <th scope="col">Mã bản</th>
                            <th scope="col">Vị trí lưu giữ</th>
                            <th scope="col">Tình trạng bản</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="item" items="${items}">
                            <tr>
                                <td class="code"><c:out value="${item.itemCode}"/></td>
                                <td><c:out value="${item.location}"/></td>
                                <td>
                                    <span class="item-state ${item.itemStatus eq 'AVAILABLE' ? 'in-stock' : ''}">
                                        <c:out value="${itemLabels[item.itemStatus]}"/>
                                    </span>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </div>
        </c:otherwise>
    </c:choose>
</c:if>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
