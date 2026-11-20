<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="pageTitle" value="Chi tiết lần mượn"/>
<c:set var="catalogView" value="${true}"/>
<c:set var="pageStylesheet" value="/assets/css/gdChiTietPhieuMuon.css"/>
<%@ include file="/WEB-INF/view/dungchung/header.jspf" %>
<c:url var="loansUrl" value="/reports/readers/loans">
    <c:param name="startDate" value="${startDate}"/>
    <c:param name="endDate" value="${endDate}"/>
    <c:param name="readerId" value="${readerId}"/>
</c:url>
<c:url var="slipUrl" value="/reports/readers/slip">
    <c:param name="startDate" value="${startDate}"/>
    <c:param name="endDate" value="${endDate}"/>
    <c:param name="readerId" value="${readerId}"/>
    <c:param name="loanId" value="${loan.id}"/>
</c:url>
<a class="back" href="<c:out value="${loansUrl}"/>">← Danh sách lần mượn</a>
<div class="page-heading">
    <div class="report-title">
        <h2 class="module-subtitle">Chi tiết lần mượn</h2>
        <span class="report-code">Mã phiếu <strong><c:out value="${loan.loanNumber}"/></strong></span>
    </div>
    <a class="button" href="<c:out value="${slipUrl}"/>">Xem phiếu mượn</a>
</div>
<p class="search-hint">Kỳ thống kê <c:out value="${periodLabel}"/></p>
<section class="panel metadata" aria-labelledby="loan-summary">
    <h2 id="loan-summary">Thông tin lần mượn</h2>
    <dl class="details">
        <div><dt>Mã độc giả</dt><dd><c:out value="${loan.reader.readerCode}"/></dd></div>
        <div><dt>Họ tên độc giả</dt><dd><c:out value="${loan.reader.fullName}"/></dd></div>
        <div><dt>Ngày giờ mượn</dt><dd><c:out value="${checkoutLabel}"/></dd></div>
        <div><dt>Nhân viên xử lý</dt><dd><c:out value="${loan.processedBy.fullName}"/></dd></div>
    </dl>
</section>
<section class="results-panel report-results" aria-labelledby="loan-items">
    <header class="results-header">
        <h2 id="loan-items">Các bản đã mượn</h2>
        <span><c:out value="${loan.loanDetails.size()}"/> bản</span>
    </header>
    <div class="table-scroll" tabindex="0" role="region" aria-labelledby="loan-items">
        <table class="detail-table">
            <thead>
                <tr>
                    <th scope="col">Mã bản</th>
                    <th scope="col">Mã tài liệu</th>
                    <th scope="col">Tên tài liệu</th>
                    <th scope="col">Hạn trả</th>
                    <th scope="col">Tình trạng trả</th>
                </tr>
            </thead>
            <tbody>
                <c:forEach var="detail" items="${loan.loanDetails}">
                    <c:set var="doc" value="${documentsByItemId[detail.item.id]}"/>
                    <tr>
                        <td class="code"><c:out value="${detail.item.itemCode}"/></td>
                        <td class="code"><c:out value="${doc.documentCode}"/></td>
                        <td><c:out value="${doc.title}"/></td>
                        <td><c:out value="${detailDueDates[detail.id]}"/></td>
                        <td>
                            <c:choose>
                                <c:when test="${not empty returnLabels[detail.id]}">
                                    <span class="item-state in-stock">Đã trả</span>
                                    <small class="return-time"><c:out value="${returnLabels[detail.id]}"/></small>
                                </c:when>
                                <c:otherwise><span class="item-state">Chưa trả</span></c:otherwise>
                            </c:choose>
                        </td>
                    </tr>
                </c:forEach>
            </tbody>
        </table>
    </div>
</section>
<%@ include file="/WEB-INF/view/dungchung/footer.jspf" %>
